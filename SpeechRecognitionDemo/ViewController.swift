//
//  ViewController.swift
//  SpeechRecognitionDemo
//
//  Created by Jayesh Kawli on 3/14/17.
//  Copyright © 2017 Jayesh Kawli. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    // A label for showing instructions while speech recognition is in progress.
    @IBOutlet weak var speechTextLabel: UILabel!

    // A button to begin/terminate or toggle the speech recognition.
    @IBOutlet weak var speechButton: UIButton!

    // A utility to easily use the speech recognition facility.
    var speechRecognizerUtility: SpeechRecognitionUtility?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Spanish Translation Request"
        speechButton.setTitle("Begin Translation...", for: .normal)
        speechTextLabel.text = "Press Begin Translation button to start translation"
    }

    @IBAction func saySomethingButtonPressed(_ sender: Any) {
        if speechRecognizerUtility == nil {
            // Initialize the speech recognition utility here
            speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                self?.toggleSpeechRecognitionState()
            }, stateUpdateBlock: { [weak self] (currentSpeechRecognitionState, toTranslate) in
                // A block to update the status of speech recognition. This block will get called every time Speech framework recognizes the speech input
                self?.stateChangedWithNew(state: currentSpeechRecognitionState)
                // We won't perform translation until final input is ready. We will usually wait for users to finish speaking their input until translation request is sent
                if toTranslate {
                    self?.toggleSpeechRecognitionState()
                    self?.speechRecognitionDone()
                }
            }, recordingState: .continuous) // We will set state to continuous so that stateUpdateBlock is called for every recognized speech segment.
        } else {
            // We will call this method to toggle the state on/off of speech recognition operation.
            self.toggleSpeechRecognitionState()
        }
    }

    func speechRecognitionDone() {
        // Trigger the request to get translations as soon as user has done providing full speech input. Don't trigger until query length is at least one.
        if let query = self.speechTextLabel.text, query.count > 0 {
            self.speechTextLabel.text = "Please wait while we get translations from server"
            self.speechTextLabel.textColor = .black
            // Disable the toggle speech button while we're getting translations from server.
            toggleSpeechButtonAccessState(enabled: false)
            NetworkRequest.sendRequestWith(query: query, completion: { (translation) in
                OperationQueue.main.addOperation {
                    // Explicitly execute the code on main thread since the request we get back need not be on the main thread.
                    self.speechTextLabel.textColor = .green
                    self.speechTextLabel.text = translation
                    self.speechButton.setTitle("Begin new translation", for: .normal)
                    // Re-enable the toggle speech button once translations are ready.
                    self.toggleSpeechButtonAccessState(enabled: true)
                }
            })
        }
    }

    // A method to toggle the userInteractionState of toggle speech state button
    func toggleSpeechButtonAccessState(enabled: Bool) {
        self.speechButton.isUserInteractionEnabled = enabled
        if enabled {
            self.speechButton.alpha = 1.0
        } else {
            self.speechButton.alpha = 0.2
        }
    }

    // A method to toggle the speech recognition state between on/off
    private func toggleSpeechRecognitionState() {
        do {
            try self.speechRecognizerUtility?.toggleSpeechRecognitionActivity()
        } catch SpeechRecognitionOperationError.denied {
            print("Speech Recognition access denied")
        } catch SpeechRecognitionOperationError.notDetermined {
            print("Unrecognized Error occurred")
        } catch SpeechRecognitionOperationError.restricted {
            print("Speech recognition access restricted")
        } catch SpeechRecognitionOperationError.audioSessionUnavailable {
            print("Audio session unavailable")
        } catch SpeechRecognitionOperationError.inputNodeUnavailable {
            print("Input node unavailable")
        } catch SpeechRecognitionOperationError.invalidRecognitionRequest {
            print("Recognition request is null. Expected non-null value")
        } catch SpeechRecognitionOperationError.audioEngineUnavailable {
            print("Audio engine is unavailable. Cannot perform speech recognition")
        } catch {
            print("Unknown error occurred")
        }
    }

    private func stateChangedWithNew(state: SpeechRecognitionOperationState) {
        switch state {
            case .authorized:
                print("State: Speech recognition authorized")
            case .audioEngineStart:
                self.speechTextLabel.text = "Provide input to translate"
                self.speechTextLabel.textColor = .black
                self.speechButton.setTitle("Stop translation", for: .normal)
                print("State: Audio Engine Started")
            case .audioEngineStop:
                print("State: Audio Engine Stopped")
            case .recognitionTaskCancelled:
                print("State: Recognition Task Cancelled")
            case .speechRecognized(let recognizedString):
                self.speechTextLabel.text = recognizedString
                self.speechTextLabel.textColor = .green
                print("State: Recognized String \(recognizedString)")
            case .speechNotRecognized:
                print("State: Speech Not Recognized")
            case .availabilityChanged(let availability):
                print("State: Availability changed. New availability \(availability)")
            case .speechRecognitionStopped(let finalRecognizedString):
                self.speechButton.setTitle("Getting translations.....", for: .normal)
                self.speechTextLabel.textColor = .black
                print("State: Speech Recognition Stopped with final string \(finalRecognizedString)")
        }
    }

}

