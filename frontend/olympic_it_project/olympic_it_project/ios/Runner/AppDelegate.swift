override func applicationWillResignActive(_ application: UIApplication) {
    self.window?.isHidden = true
}

override func applicationDidBecomeActive(_ application: UIApplication) {
    self.window?.isHidden = false
}