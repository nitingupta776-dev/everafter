import Flutter
import CoreNFC
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nfcChannel: FlutterMethodChannel?
  private var nfcReader: EverAfterNfcReader?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let reader = EverAfterNfcReader()
    let channel = FlutterMethodChannel(
      name: "com.example.everafter/nfc",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak reader] call, result in
      guard call.method == "scanMagnet" else {
        result(FlutterMethodNotImplemented)
        return
      }
      reader?.scan(result: result)
    }
    nfcReader = reader
    nfcChannel = channel
  }
}

private final class EverAfterNfcReader: NSObject, NFCTagReaderSessionDelegate {
  private var session: NFCTagReaderSession?
  private var pendingResult: FlutterResult?

  func scan(result: @escaping FlutterResult) {
    guard NFCNDEFReaderSession.readingAvailable else {
      result(
        FlutterError(
          code: "unavailable",
          message: "NFC scanning is not available on this iPhone.",
          details: nil
        )
      )
      return
    }
    guard pendingResult == nil else {
      result(
        FlutterError(
          code: "already_scanning",
          message: "EverAfter is already looking for a magnet.",
          details: nil
        )
      )
      return
    }
    guard let readerSession = NFCTagReaderSession(
      pollingOption: [.iso14443],
      delegate: self,
      queue: nil
    ) else {
      result(
        FlutterError(
          code: "unavailable",
          message: "EverAfter could not start the NFC reader.",
          details: nil
        )
      )
      return
    }

    pendingResult = result
    session = readerSession
    readerSession.alertMessage = "Hold the top of your iPhone near an EverAfter magnet."
    readerSession.begin()
  }

  func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

  func tagReaderSession(
    _ session: NFCTagReaderSession,
    didInvalidateWithError error: Error
  ) {
    self.session = nil
    guard pendingResult != nil else { return }

    let readerError = error as? NFCReaderError
    if readerError?.code == .readerSessionInvalidationErrorUserCanceled {
      finish(
        error: FlutterError(
          code: "cancelled",
          message: "The NFC scan was cancelled.",
          details: nil
        )
      )
      return
    }

    let message: String
    if readerError?.code == .readerSessionInvalidationErrorSessionTimeout {
      message = "No magnet was found. Move the top of your iPhone closer and try again."
    } else {
      message = "EverAfter could not read the magnet. Please try again."
    }
    finish(error: FlutterError(code: "scan_failed", message: message, details: nil))
  }

  func tagReaderSession(
    _ session: NFCTagReaderSession,
    didDetect tags: [NFCTag]
  ) {
    guard tags.count == 1, let tag = tags.first else {
      session.alertMessage = "More than one magnet is nearby. Hold only one near your iPhone."
      session.restartPolling()
      return
    }

    session.connect(to: tag) { [weak self, weak session] error in
      guard let self, let session else { return }
      if error != nil {
        session.alertMessage = "Keep the magnet still near the top of your iPhone."
        session.restartPolling()
        return
      }
      guard let identifier = self.identifier(for: tag), !identifier.isEmpty else {
        session.alertMessage = "This NFC tag does not expose a readable identifier."
        session.invalidate()
        self.finish(
          error: FlutterError(
            code: "unsupported_tag",
            message: "This magnet uses an unsupported NFC tag.",
            details: nil
          )
        )
        return
      }

      let uid = identifier.map { String(format: "%02X", $0) }.joined(separator: ":")
      session.alertMessage = "Magnet scanned. Opening your trip…"
      self.finish(value: uid)
      session.invalidate()
    }
  }

  private func identifier(for tag: NFCTag) -> Data? {
    switch tag {
    case .miFare(let mifareTag):
      return mifareTag.identifier
    case .iso7816(let iso7816Tag):
      return iso7816Tag.identifier
    case .iso15693(let iso15693Tag):
      return iso15693Tag.identifier
    case .feliCa(let feliCaTag):
      return feliCaTag.currentIDm
    @unknown default:
      return nil
    }
  }

  private func finish(value: String) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    DispatchQueue.main.async { result(value) }
  }

  private func finish(error: FlutterError) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    DispatchQueue.main.async { result(error) }
  }
}
