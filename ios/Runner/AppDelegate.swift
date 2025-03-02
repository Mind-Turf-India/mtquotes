import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    var window: UIWindow?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Prevent screenshots and screen recording
        if let window = UIApplication.shared.windows.first {
            let field = UITextField()
            field.isSecureTextEntry = true
            window.addSubview(field)
            field.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
            field.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                field.removeFromSuperview()
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
