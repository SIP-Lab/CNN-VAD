//
//  ViewController.swift
//  CNN_VAD
//
//  Created by Abhishek Sehgal on 9/22/17.
//  Copyright © 2017 SIPLab. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //UI Elements
    @IBOutlet weak var uiTitle: UILabel!
    @IBOutlet weak var labName: UILabel!
    @IBOutlet weak var labelNoise: UILabel!
    @IBOutlet weak var labelSpeech: UILabel!
    @IBOutlet weak var labelProcessingTime: UILabel!
    @IBOutlet weak var labelUpdateRate: UILabel!
    @IBOutlet weak var buttonStart: UIButton!
    @IBOutlet weak var buttonStop: UIButton!
    @IBOutlet weak var sliderUpdateRate: UISlider!
    @IBOutlet weak var switchStore: UISwitch!
    

    var predictTimer = Timer()
    var prediction = float_t()
    var count = 0
    
    //User Defined Functions
    
    func buttonEnable(enable: Bool){
        buttonStart.isEnabled = enable
        buttonStop.isEnabled = !enable
        sliderUpdateRate.isEnabled = enable
        switchStore.isEnabled = enable
        
        if(enable){
            buttonStart.backgroundColor = UIColor(red: 51.0/255.0, green: 153.0/255.0, blue: 0, alpha: 1)
            buttonStop.backgroundColor  = UIColor.lightGray
        } else {
            buttonStart.backgroundColor = UIColor.lightGray
            buttonStop.backgroundColor  = UIColor(red: 204.0/255.0, green: 0, blue: 0, alpha: 1)
        }
        
    }
    
    @IBAction func buttonStartClick(_ sender: Any) {
        
        buttonEnable(enable: false)
        audioRecorder.start()
        
        predictTimer = Timer.scheduledTimer(withTimeInterval: 0.0625,
                                     repeats: true,
                                     block: {
                                        _ in audioRecorder.predict();
                                        self.count = self.count + 1
                                        
                                        if(self.count > Int(self.sliderUpdateRate.value) + 1 && audioRecorder.predictBuffer.count > 10){
                                            self.labelProcessingTime.text = "Frame Processing Time: \(round(100000*audioRecorder.timeBuffer.movingAverage)/100) ms"
                                            if(audioRecorder.predictBuffer.movingAverage > 0.5){
                                                self.labelNoise.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1);
                                                self.labelSpeech.backgroundColor = UIColor(red: 51.0/255.0, green: 153.0/255.0, blue: 0, alpha: 1);
                                            } else {
                                                self.labelNoise.backgroundColor = UIColor(red: 204.0/255.0, green: 0, blue: 0, alpha: 1);
                                                self.labelSpeech.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1);
                                            }
                                            self.count = 0;
                                        }
                                        
        })
    }
    
    @IBAction func buttonStopClick(_ sender: Any) {
        predictTimer.invalidate()
        buttonEnable(enable: true)
        audioRecorder.stop()
    }
    
    @IBAction func sliderUpdateRateChanged(_ sender: Any) {
        sliderUpdateRate.value = round(sliderUpdateRate.value);
        labelUpdateRate.text = "GUI Update Rate \(100 + 50*Int(round(sliderUpdateRate.value))) ms"
    }
    
    
    //Pre-Defined Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        uiTitle.text = "Convolutional Neural Network\nVoice Activity Detector"
        labName.text = "Signal and Image Processing Lab\nUniversity of Texas at Dallas"
        labelProcessingTime.text = "Frame Processing Time: "
        labelUpdateRate.text = "GUI Update Rate: 100ms"
        audioRecorder = AudioRecorder()
        
        buttonEnable(enable: true)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

