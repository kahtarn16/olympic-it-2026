import Flutter
import UIKit

class AntiCheatStreamHandler: NSObject, FlutterStreamHandler {

    var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {

        eventSink = events

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {

        NotificationCenter.default.removeObserver(self)

        eventSink = nil

        return nil
    }

    @objc func screenshotTaken() {

        eventSink?("screenshot")

    }

    @objc func screenCaptureChanged() {

        if UIScreen.main.isCaptured {

            eventSink?("recording")

        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  let antiCheatHandler = AntiCheatStreamHandler()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
