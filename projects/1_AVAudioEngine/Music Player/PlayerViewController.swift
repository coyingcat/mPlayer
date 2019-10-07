

import UIKit
import AVFoundation

import MediaPlayer

class PlayerViewController: UIViewController{
    
    //Choose background here. Between 1 - 7
    let selectedBackground = 1
    lazy var enginePlayer = { () -> Streamer in
        let player = Streamer()
        player.delegate = self
        return player
    }()
    
    var currentAudio = ""
    var currentAudioPath:URL!
    
    
    var audioList:NSArray!
    var currentAudioIndex = 0
    var timer:Timer!
    
    
    var audioLength = 0.0
    var effectToggle = true
    
    
    var totalLengthOfAudio = ""
    var finalImage:UIImage!
    var isTableViewOnscreen = false
    
    
    var shuffleState = false
    var repeatState = false
    var shuffleCluster = Set<Int>()
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet var lineView : UIView!
    
    
    @IBOutlet weak var albumArtworkImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    
    
    @IBOutlet var songNameLabel : UILabel!
    
    @IBOutlet var progressTimerLabel : UILabel!
    
    // 我想要的
    @IBOutlet var playerProgressSlider : UISlider!
    @IBOutlet var totalLengthOfAudioLabel : UILabel!
    @IBOutlet var previousButton : UIButton!
    
    
    @IBOutlet var playButton : UIButton!
    @IBOutlet var nextButton : UIButton!
    @IBOutlet var listButton : UIButton!
    
    
    @IBOutlet var tableView : UITableView!
    

    @IBOutlet var tableViewContainer : UIView!
    
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var tableViewContainerTopConstrain: NSLayoutConstraint!
    
    
    @IBOutlet weak var stateTip: UILabel!
    
    //MARK:- Lockscreen Media Control
    
    // This shows media info on lock screen - used currently and perform controls
    func showMediaInfo(){
        let artistName = readArtistNameFromPlist(currentAudioIndex)
        let songName = readSongNameFromPlist(currentAudioIndex)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist : artistName,  MPMediaItemPropertyTitle : songName]
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        if event!.type == UIEvent.EventType.remoteControl{
            switch event!.subtype{
            case UIEventSubtype.remoteControlPlay:
                play(playButton)
            case UIEventSubtype.remoteControlPause:
                play(playButton)
            case UIEventSubtype.remoteControlNextTrack:
                next(self)
            case UIEventSubtype.remoteControlPreviousTrack:
                previous(self)
            default:
                print("There is an issue with the control")
            }
        }
    }
    
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    override var prefersStatusBarHidden : Bool {
        if isTableViewOnscreen{
            return true
        }else{
            return false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showState(UserSettings.shared.isInShuffle, UserSettings.shared.isInRepeat)
        //   background
        backgroundImageView.image = UIImage(named: "background\(selectedBackground)")
        let playImg = UIImage(named: "play")
        // is playing, to pause
        let pauseImg = UIImage(named: "pause")
        playButton.setImage(playImg, for: UIControl.State.normal)
        playButton.setImage(pauseImg, for: UIControl.State.selected)
        
        // this sets last listened trach number as current
        currentAudioIndex = UserSettings.shared.currentAudioIndex
        prepareAudio()
        updateLabels()
        assingSliderUI()
        setRepeatAndShuffle()
        retrievePlayerProgressSliderValue()
        //LockScreen Media control registry
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)){
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
    }

    
    func setRepeatAndShuffle(){
        shuffleButton.isSelected = UserSettings.shared.isInShuffle
        repeatButton.isSelected = UserSettings.shared.isInRepeat
    }
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableViewContainerTopConstrain.constant = 1000.0
        self.tableViewContainer.layoutIfNeeded()
        blurView.isHidden = true
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        albumArtworkImageView.setRounded()
    }
    

  
    //Sets audio file URL
    func setCurrentAudioPath(){
        currentAudio = readSongNameFromPlist(currentAudioIndex)
        if let path = Bundle.main.path(forResource: currentAudio, ofType: "mp3"){
            currentAudioPath = URL(fileURLWithPath: path)
        }
        else{
            alertSongExsit()
        }
    }
    

    func alertSongExsit(){
        let alert = UIAlertController(title: "Music Error", message: "No songs Exsit", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "Cancel it", style: UIAlertAction.Style.cancel) { (action) in            }
        alert.addAction(action)
        present(alert, animated: true, completion: {})
    }
    
    
    // Prepare audio for playing
    func prepareAudio(){
        setCurrentAudioPath()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        guard currentAudioPath != nil else {
            alertSongExsit()
            return
        }
        enginePlayer.url = currentAudioPath
        guard let lasting = enginePlayer.duration else{
            return
        }
        audioLength = lasting
        
        playerProgressSlider.maximumValue = Float(audioLength)
        playerProgressSlider.minimumValue = 0.0
        playerProgressSlider.value = 0.0
        
        
        showTotalSongLength()
        updateLabels()
        progressTimerLabel.text = "00:00"
        
    }
    
    
    
    //MARK:- Player Controls Methods
    func  playAudio(){
    
        enginePlayer.play()
        startTimer()
        updateLabels()
        
        UserSettings.shared.currentAudioIndex = currentAudioIndex
        
        showMediaInfo()
    }
    
    
    func playNextAudio(){
        
        currentAudioIndex += 1
        if currentAudioIndex>audioList.count-1{
            currentAudioIndex -= 1
            return
        }
        prepareAudio()
        if enginePlayer.isPlaying{
            playAudio()
        }
    }
    
    
    func playPreviousAudio(){
        
        currentAudioIndex -= 1
        if currentAudioIndex<0{
            currentAudioIndex += 1
            return
        }
        prepareAudio()
        if enginePlayer.isPlaying{
            playAudio()
        }
        
    }
    
    
    func stopAudiplayer(){
        enginePlayer.stop()
        
    }
    
    func pauseAudioPlayer(){
        enginePlayer.pause()
    }
    
    
    //MARK:- Timer
    
    func startTimer(){
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlayerViewController.update(_:)), userInfo: nil,repeats: true)
            timer.fire()
        }
    }
    
    func stopTimer(){
        timer.invalidate()
        
    }
    
    
    @objc func update(_ timer: Timer){
        
        
        guard enginePlayer.isPlaying, let cur = enginePlayer.currentTime else{
            return
        }
        let time = calculateTimeFrom(cur)
        progressTimerLabel.text  = "\(time.minute):\(time.second)"
        playerProgressSlider.value = Float(cur)
        UserSettings.shared.playerProgress = playerProgressSlider.value
        
    }
    
    
    
    
    
    func retrievePlayerProgressSliderValue(){
        
        let playerProgressSliderValue = UserSettings.shared.playerProgress
        if playerProgressSliderValue == 0 {
            playerProgressSlider.value = 0.0
            try? enginePlayer.seek(to: 0)
            progressTimerLabel.text = "00:00:00"
        }else{
            try? enginePlayer.seek(to: TimeInterval(playerProgressSliderValue))
            if let stamp = enginePlayer.currentTime{
                let time = calculateTimeFrom(stamp)
                progressTimerLabel.text  = "\(time.minute):\(time.second)"
                playerProgressSlider.value = Float(stamp)
            }
            
        }
    }

    
    
    //This returns song length
    func calculateTimeFrom(_ duration: TimeInterval) ->(minute:String, second:String){
       // let hour_   = abs(Int(duration)/3600)
        let minute_ = abs(Int((duration/60).truncatingRemainder(dividingBy: 60)))
        let second_ = abs(Int(duration.truncatingRemainder(dividingBy: 60)))
        
        let minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        let second = second_ > 9 ? "\(second_)" : "0\(second_)"
        return (minute,second)
    }
    

    
    func showTotalSongLength(){
        calculateSongLength()
        totalLengthOfAudioLabel.text = totalLengthOfAudio
    }
    
    
    func calculateSongLength(){
        let time = calculateTimeFrom(audioLength)
        totalLengthOfAudio = "\(time.minute):\(time.second)"
    }
    
    
    //Read plist file and creates an array of dictionary
    func readFromPlist(){
        let path = Bundle.main.path(forResource: "list", ofType: "plist")
        audioList = NSArray(contentsOfFile:path!)
    }
    
    func readArtistNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        let infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let artistName = infoDict.value(forKey: "artistName") as! String
        return artistName
    }
    
    func readAlbumNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        let infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let albumName = infoDict.value(forKey: "albumName") as! String
        return albumName
    }

    
    func readSongNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        let songNameDict = audioList.object(at: indexNumber) as! NSDictionary
        let songName = songNameDict.value(forKey: "songName") as! String
        return songName
    }
    
    func readArtworkNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        let infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let artworkName = infoDict.value(forKey: "albumArtwork") as! String
        return artworkName
    }

    
    func updateLabels(){
        updateArtistNameLabel()
        updateAlbumNameLabel()
        updateSongNameLabel()
        updateAlbumArtwork()

        
    }
    
    
    func updateArtistNameLabel(){
        let artistName = readArtistNameFromPlist(currentAudioIndex)
        artistNameLabel.text = artistName
    }
    func updateAlbumNameLabel(){
        let albumName = readAlbumNameFromPlist(currentAudioIndex)
        albumNameLabel.text = albumName
    }
    
    func updateSongNameLabel(){
        let songName = readSongNameFromPlist(currentAudioIndex)
        songNameLabel.text = songName
    }
    
    func updateAlbumArtwork(){
        let artworkName = readArtworkNameFromPlist(currentAudioIndex)
        albumArtworkImageView.image = UIImage(named: artworkName)
    }
    
  
    //creates animation and push table view to screen
    func animateTableViewToScreen(){
        self.blurView.isHidden = false
        UIView.animate(withDuration: 0.15, delay: 0.01, options:
            UIView.AnimationOptions.curveEaseIn, animations: {
            self.tableViewContainerTopConstrain.constant = 0.0
            self.tableViewContainer.layoutIfNeeded()
            }, completion: { (bool) in
        })
        
    }
    
    
    
    
    func animateTableViewToOffScreen(){
        isTableViewOnscreen = false
        setNeedsStatusBarAppearanceUpdate()
        self.tableViewContainerTopConstrain.constant = 1000.0
        UIView.animate(withDuration: 0.20, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
           self.tableViewContainer.layoutIfNeeded()
            
            }, completion: {
                (value: Bool) in
                self.blurView.isHidden = true
        })
    }
    
    
   
    func assingSliderUI() {
        let minImage = UIImage(named: "slider-track-fill")
        let maxImage = UIImage(named: "slider-track")
        let thumb = UIImage(named: "thumb")
        playerProgressSlider.isContinuous = false
        playerProgressSlider.setMinimumTrackImage(minImage, for: UIControl.State())
        playerProgressSlider.setMaximumTrackImage(maxImage, for: UIControl.State())
        playerProgressSlider.setThumbImage(thumb, for: UIControl.State())

    
    }
    
    //MARK:- Target Action
    
    
    @IBAction func play(_ sender: UIButton) {
    
        sender.isSelected.toggle()
        if shuffleState == true {
            shuffleCluster.removeAll()
        }
        
        if enginePlayer.isPlaying{
            pauseAudioPlayer()
        }else{
            playAudio()
        }
    }
    
    
    
    @IBAction func next(_ sender : AnyObject) {
        playNextAudio()
    }
    
    
    @IBAction func previous(_ sender : AnyObject) {
        playPreviousAudio()
    }
    
    
    
    
    @IBAction func changeAudioLocationSlider(_ sender : UISlider) {
       
        try? enginePlayer.seek(to: TimeInterval(sender.value))
    }
    
    
    @IBAction func userTapped(_ sender : UITapGestureRecognizer) {
        play(playButton)
    }
    
    @IBAction func userSwipeLeft(_ sender : UISwipeGestureRecognizer) {
        next(self)
    }
    
    @IBAction func userSwipeRight(_ sender : UISwipeGestureRecognizer) {
        previous(self)
    }
    
    @IBAction func userSwipeUp(_ sender : UISwipeGestureRecognizer) {
        presentListTableView(self)
    }
    
    
    @IBAction func shuffleButtonTapped(_ sender: UIButton) {
        shuffleCluster.removeAll()
        sender.isSelected.toggle()
        shuffleState = sender.isSelected
        UserSettings.shared.isInShuffle = sender.isSelected
        showState(sender.isSelected, repeatButton.isSelected)
    }
    
    
    @IBAction func repeatButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        repeatState = sender.isSelected
        UserSettings.shared.isInRepeat = sender.isSelected
        showState(shuffleButton.isSelected, sender.isSelected)
    }
    
    
    
    func showState(_ isInShuffle: Bool, _ isInLoops: Bool){
        switch (isInShuffle, isInLoops) {
        case (true, true):
            stateTip.text = PlayRules.shuffleLoops.rawValue
        case (true, false):
            stateTip.text = PlayRules.shuffleNoLoop.rawValue
        case (false, true):
            stateTip.text = PlayRules.loopNoShuffle.rawValue
        case (false, false):
            stateTip.text = PlayRules.none.rawValue
        }
    }
    
    
    
    @IBAction func presentListTableView(_ sender : AnyObject) {
        if effectToggle{
            isTableViewOnscreen = true
            setNeedsStatusBarAppearanceUpdate()
            animateTableViewToScreen()
            
        }else{
            animateTableViewToOffScreen()
            
        }
        effectToggle = !effectToggle
        let showList = UIImage(named: "list")
        let removeList = UIImage(named: "listS")
        if effectToggle{
            listButton.setImage( showList, for: UIControl.State())
        }
        else{
            listButton.setImage(removeList , for: UIControl.State())
        }
        
    }

}






extension PlayerViewController: UITableViewDelegate{
    
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        animateTableViewToOffScreen()
        currentAudioIndex = (indexPath as NSIndexPath).row
        prepareAudio()
        playAudio()
        effectToggle = !effectToggle
        let showList = UIImage(named: "list")
        let removeList = UIImage(named: "listS")
        if effectToggle {
            listButton.setImage( showList, for: UIControl.State())
        }
        else{
            listButton.setImage(removeList , for: UIControl.State())
        }
        playButton.isSelected = enginePlayer.isPlaying
        blurView.isHidden = true
    }
    
}







extension PlayerViewController: UITableViewDataSource{
    


    //MARK-


    // Table View Part of the code. Displays Song name and Artist Name
    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        var songNameDict = NSDictionary();
        songNameDict = audioList.object(at: (indexPath as NSIndexPath).row) as! NSDictionary
        let songName = songNameDict.value(forKey: "songName") as! String
        
        var albumNameDict = NSDictionary();
        albumNameDict = audioList.object(at: (indexPath as NSIndexPath).row) as! NSDictionary
        let albumName = albumNameDict.value(forKey: "albumName") as! String
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-BookIta", size: 25.0)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = songName
        
        cell.detailTextLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-Book", size: 16.0)
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.text = albumName
        return cell
    }



    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }



    func tableView(_ tableView: UITableView,willDisplay cell: UITableViewCell,forRowAt indexPath: IndexPath){
        tableView.backgroundColor = UIColor.clear
        
        let backgroundView = UIView(frame: CGRect.zero)
        backgroundView.backgroundColor = UIColor.clear
        cell.backgroundView = backgroundView
        cell.backgroundColor = UIColor.clear
    }

}




extension PlayerViewController{

    func audioPlayerDidFinishPlaying(){

            switch (shuffleState, repeatState){
            case (false, false):
                // do nothing
                playButton.isSelected = false
                return
            case (false, true):
                //repeat same song
                prepareAudio()
                playAudio()
            case (true, false):
                //shuffle songs but do not repeat at the end
                //Shuffle Logic : Create an array and put current song into the array then when next song come randomly choose song from available song and check against the array it is in the array try until you find one if the array and number of songs are same then stop playing as all songs are already played.
                shuffleCluster.insert(currentAudioIndex)
                if shuffleCluster.count >= audioList.count {
                    playButton.isSelected = false
                    return
                }
                let available = Set<Int>(0...(audioList.count-1))
                let rest = available.subtracting(shuffleCluster)
                currentAudioIndex = Int(arc4random_uniform(UInt32(rest.count)))
                prepareAudio()
                playAudio()
            case (true, true):
                //shuffle song endlessly
                shuffleCluster.insert(currentAudioIndex)
                if shuffleCluster.count >= audioList.count {
                    shuffleCluster.removeAll()
                }
                let available = Set<Int>(0...(audioList.count-1))
                let rest = available.subtracting(shuffleCluster)
                currentAudioIndex = Int(arc4random_uniform(UInt32(rest.count)))
                prepareAudio()
                playAudio()
                
            }
        
    }

}





extension AVAudioFile{
    
    var duration: TimeInterval{
        let sampleRateSong = Double(processingFormat.sampleRate)
        let lengthSongSeconds = Double(length) / sampleRateSong
        return lengthSongSeconds
    }
    
}



extension PlayerViewController: StreamingDelegate{
    func streamer(_ streamer: Streaming, updatedDuration currentTime: TimeInterval) {
        guard let lasting = streamer.duration else {
            return
        }
        if abs(lasting - currentTime) < 0.3{
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                self.audioPlayerDidFinishPlaying()
            }
        }
    }
}
