//
//  ViewController.swift
//  VoiceDictionary
//
//  Created by Amirhossein Sayyah on 7/1/18.
//  Copyright © 2018 Amirhossein Sayyah. All rights reserved.
//

import UIKit
import Speech
import SwiftyJSON
import Alamofire

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var detectedTextView: UITextView!
    @IBOutlet weak var translatedTextView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = 0
    var myString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //useDictionary()
        // Do any additional setup after loading the view, typically from a nib.
        requestSpeechAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton){
        if(isRecording == 0){
            isRecording = 1
            startButton.setTitle("stop", for: .normal)
            self.recordAndRecognizeSpeech()
        }
        else{
            isRecording = 0
            startButton.setTitle("start", for: .normal)
            self.stopRecording()
        }
        
    }
    
    func recordAndRecognizeSpeech(){
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
            
        }
        
        audioEngine.prepare()
        do{
            try audioEngine.start()
        } catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {return}
        
        if !myRecognizer.isAvailable {
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.myString = bestString
                self.detectedTextView.text = bestString
            } else if let result = error {
                print(error)
            }
        })
        
    }
    
    func stopRecording(){
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request.endAudio()
        recognitionTask?.cancel()
    }
    
    func requestSpeechAuthorization(){
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.startButton.isEnabled = true
                case .notDetermined:
                    self.startButton.isEnabled = false
                case .denied:
                    self.startButton.isEnabled = false
                case .restricted:
                    self.startButton.isEnabled = false
                
                }
            }
        }
    }
    
    @IBAction func doTranslation(_ sender: UIButton){
        useDictionary()
    }
    
    func useDictionary(){
        let language = "en"
        let word = self.myString
        let newWord = word.replacingOccurrences(of: " ", with: "_", options: .literal, range: nil)
        let word_id = newWord.lowercased() //word id is case sensitive and lowercase is required
        let url = URL(string: "https://od-api.oxforddictionaries.com:443/api/v1/entries/\(language)/\(word_id)")!
        
        let headers = [
            "app_id": "Your Oxford app-id goes here!",
            "app_key": "Your Oxford app-key goes here!",
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, headers: headers).responseJSON {
            response in
            var json = response.result.value //A JSON object
            var isSuccess = response.result.isSuccess
            if (isSuccess && (json != nil)) {
                //use json here ///////////////
                //print(JSON(json)["results"])
                //var answer: String = \("")
                let answer =  "\(JSON(json)["results"][0]["lexicalEntries"][0]["entries"][0]["senses"][0]["definitions"][0])"
                if(answer != ""){
                    self.translatedTextView.text = answer
                }else{
                    self.translatedTextView.text = "No translation found!"
                }
                
                
            }else{
                //self.view.showToast("Something went wrong. Please try again.", position: .bottom, popTime: 3, dismissOnTap: true)
            }
            
        }
    }

}

