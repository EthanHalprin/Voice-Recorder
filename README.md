# Voice-Recorder
See your speech recognised and texted instantly on screen &amp; saved to file



Voice Recorder - just like the name suggests: records what you say and you see this immediately on screen in a UITextView. If you wanna save to file - press 'Save'.

USER PERMISSIONS
Voice Recorder uses Speech Recognition and Microphone for use, so mind to check relevant obligatory entries on plist (prefixed "Privacy - ..."). User must give his consent, otherwise - no record can be done. I check this clearance and do not try record if User refused. So should you.
Also mind that I flicker UILabel in red for indicating that recording is on. It is recommended highly to show user when recording is done.
A method for internet connection is also supplied. Speech Recognition requires it, since Apple may send data to its servers for improving the technology. highly recommended to inform user with that too.

PROCEDURE
Participating main classes in the recording procedure:
AVAudioEngine
AVAudioInputNode
SFSpeechRecognizer
SFSpeechRecognitionTask
SFSpeechAudioBufferRecognitionRequest

For starting recording, one needs to invoke a speech recognition task that takes a speech recognition request. This request needs a buffer to be appended to, by the trailing closure of node's installTap method. The latter is indeed called in code. The input node is created thru the AVAudioEngine that is allocated in the start of the recording.
If all of this sounds complicated a bit, please see code (method `startRecording`)
Added also a IBAction read routine that is not called, but I left it there so you can hook it up and check that your file was saved.

IMPORTANT NOTE
You need a device to check this babe (microphone), I have checked it out on my iphone7Plus and it worked OK.
