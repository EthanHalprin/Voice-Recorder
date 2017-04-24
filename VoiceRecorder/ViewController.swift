//
//  ViewController.swift
//  VoiceRecorder
//
//  Created by Ethan Halprin on 23/04/2017.
//
import UIKit


class ViewController: UIViewController
{
    @IBOutlet var recordingONLabel: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var saveButton: UIButton!
    
    let speechAudio = SpeechAudioManager()
    
    var flickerTimer: Timer!
    var toggleColor = true
    
    let filename = "record"

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if !speechAudio.isInternetON()
        {
            let alertVC = UIAlertController()
            let action  = UIAlertAction(title: "Internet connection", style: UIAlertActionStyle.default, handler: nil)
            
            alertVC.message = "Apple needs internet connection for speech recognition (sending transcripts for improving technology). Please hook up via Wi-Fi or Cellular Data"
            alertVC.addAction(action)

            present(alertVC, animated: true, completion: nil)
        }
        
        let receiverSelector1 = #selector(speechRecognitionNotify)
        let notificationName1 = NSNotification.Name(rawValue: "transcriptNotify")
       
        NotificationCenter.default.addObserver(self,
                                               selector : receiverSelector1,
                                               name     : notificationName1,
                                               object   : nil)

    }
    
    internal func speechRecognitionNotify(notification : NSNotification)
    {
        guard let _ = notification.userInfo else
        {
            return
        }
        
        DispatchQueue.main.async
        {
            () -> Void in
            
            if let transcript = notification.userInfo?["transcript"] as? String?
            {
                guard self.textView.text != nil && self.textView.text != "" else
                {
                    self.textView.text = transcript
                    
                    return
                }
                
                self.textView.text! += " " + transcript!
            }
        }
    }

    @IBAction func recordTouched(_ sender: Any)
    {
        flickerTimer = Timer.scheduledTimer(timeInterval: 1,
                                            target: self,
                                            selector: #selector(runTimedCode),
                                            userInfo: nil,
                                            repeats: true)

        try? speechAudio.startRecording()
    }
    
    @IBAction func stopTouched(_ sender: Any)
    {
        flickerTimer.invalidate()

        speechAudio.stopRecording()
    }
    
    func runTimedCode()
    {
        DispatchQueue.main.async
        {
            if self.toggleColor
            {
                self.recordingONLabel.textColor = UIColor.black
            }
            else
            {
                self.recordingONLabel.textColor = UIColor.red
            }

            self.toggleColor = self.toggleColor ? false : true
        }
    }

    @IBAction func saveTouched(_ sender: Any)
    {
        let text = self.textView.text
        guard self.textView.text != nil && self.textView.text != "" else { return }

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        {
            let path = dir.appendingPathComponent(filename)
            
            //writing
            do
            {
                try text?.write(to: path, atomically: false, encoding: String.Encoding.utf8)
            }
            catch
            {
                print("Could not save transcript text")
            }
        }
    }
    
    @IBAction func readdd(_ sender: Any)
    {
        //reading
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        {
            let path = dir.appendingPathComponent(filename)

            do
            {
                let text = try String(contentsOf: path, encoding: String.Encoding.utf8)
                
                print("reading: \(text)")
            }
            catch
            {
                print("Could not read transcript text")
            }
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    deinit
    {
        flickerTimer.invalidate()
    }
}

