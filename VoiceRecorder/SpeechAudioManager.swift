//
//  SpeechAudioManager
//  VoiceRecorder
//
//  Created by Ethan Halprin on 23/04/2017.
//
import Foundation
import AVFoundation
import Speech
import SystemConfiguration

enum SpeechError : Error
{
    case RuntimeError(String)
}

class SpeechAudioManager: NSObject, SFSpeechRecognizerDelegate
{
    var audioEngine           : AVAudioEngine? = AVAudioEngine()
    var speechRecognizer      : SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    var request               : SFSpeechAudioBufferRecognitionRequest? = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask       : SFSpeechRecognitionTask?
    var node                  : AVAudioInputNode?
    var recordingFormat       : AVAudioFormat?
    var firstRecord           : Bool = true
    var isSpeechClearanceOK   : Bool = false
    var isMicClearanceOK      : Bool = false

    
    override init()
    {
        super.init()
        
        speechRecognizer?.delegate = self
        
        requestSpeechRecognitionAuthorization()
        requestMicrophoneAuthorization()
    }
    deinit
    {
        shutdownRecording()
    }
    internal func isInternetON() -> Bool
    {
        var address0 = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        
        address0.sin_len = UInt8(MemoryLayout.size(ofValue: address0))
        address0.sin_family = sa_family_t(AF_INET)
        
        let defaultConnectivity = withUnsafePointer(to: &address0)
        {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1)
            {
                sockAddress0 in
                
                SCNetworkReachabilityCreateWithAddress(nil, sockAddress0)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        
        if SCNetworkReachabilityGetFlags(defaultConnectivity!, &flags) == false
        {
            return false
        }
        
        // works for 3G and WI-Fi:
        let flagReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let connectionRequired = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return flagReachable && !connectionRequired
    }
    internal func requestSpeechRecognitionAuthorization()//resultHandler : @escaping (Bool)->())
    {
        SFSpeechRecognizer.requestAuthorization
        {
            (requestStatus) in
            
            self.isSpeechClearanceOK = (requestStatus == .authorized) ? true : false
        }
    }
    internal func requestMicrophoneAuthorization()//resultHandler : @escaping (Bool)->())
    {
        AVAudioSession.sharedInstance().requestRecordPermission()
        {
            (granted) in
            
            self.isMicClearanceOK = granted
        }
    }
    internal func startRecording() throws
    {
        guard isSpeechClearanceOK && isMicClearanceOK else
        {
            throw SpeechError.RuntimeError("User did not approve speech and/or mic access")
        }
        
        print("!!!  startRecording START  !!!")
        
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true
        
        audioEngine = AVAudioEngine()
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
        
        node = audioEngine?.inputNode!
        
        if firstRecord
        {
            firstRecord = false
        }
        
        recordingFormat = (node!.outputFormat(forBus: 0))
        
        node!.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat!)
        {
            (buffer, _) in
            
            // Append audio to end of the recognition stream. Must currently be in
            // native format.
            self.request?.append(buffer)
        }
        
        audioEngine?.prepare()
        try audioEngine?.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with : request!,
                                                            resultHandler :
            {
                result, err in
                
                if result != nil
                {
                    //
                    // Extract best transcript
                    //
                    let transcript : String = (result?.bestTranscription.formattedString)!
                    print(" Full Buff = \"\(transcript)\" ")
                    let split     = transcript.characters.split(separator: " ")
                    let lastWord  = String(split.suffix(1).joined(separator: [" "]))
                    print(" Last Word = \"\(lastWord)\" ")
                    //
                    // Fill Notification payload
                    //
                    var userINFO = Dictionary<String, String>()
                    userINFO["transcript"] = lastWord
                    let name = NSNotification.Name(rawValue: "transcriptNotify")
                    let notification = NSNotification(name: name, object: nil, userInfo: userINFO)
                    NotificationCenter.default.post(notification as Notification)
                    //
                    // if Final - release
                    //
                    if result!.isFinal
                    {
                        self.stopRecording()
                    }
                }
        })
    }
    internal func stopRecording()
    {
        guard isSpeechClearanceOK && isMicClearanceOK else
        {
            return
        }

        //
        // Remove the tap from bus (otherwise exceprion thrown)
        //
        node = audioEngine?.inputNode!
        node?.removeTap(onBus: 0)
        //
        // Stop the engine. Releases the resources allocated by prepare.
        //
        audioEngine?.stop()
        //
        // Indicate that the audio source is finished and no more audio will be appended
        //
        request?.endAudio()
        
        request          = nil
        audioEngine      = nil
        speechRecognizer = nil
        node             = nil
        
        firstRecord = true
    }
    internal func cancelRecording()
    {
        guard isSpeechClearanceOK && isMicClearanceOK else
        {
            return
        }

        //
        // Stop the engine. Releases the resources allocated by prepare.
        //
        audioEngine?.stop()
        //
        // Cancel recognition task
        //
        recognitionTask?.cancel()
    }
    internal func shutdownRecording()
    {
        print("!!!  shutdownRecording  !!!")
        
        //
        // Stop the engine. Releases the resources allocated by prepare.
        //
        self.audioEngine?.stop()
        //
        // Indicate that the audio source is finished and no more audio will be appended
        //
        self.request?.endAudio()
        //
        // Cancel recognition task
        //
        self.recognitionTask?.cancel()
        
        node?.removeTap(onBus: 0)
        
        audioEngine      = nil
        speechRecognizer = nil
        request          = nil
        recognitionTask  = nil
        recordingFormat  = nil
    }
}
