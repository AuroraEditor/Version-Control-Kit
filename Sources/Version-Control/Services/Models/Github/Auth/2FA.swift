//
//  2FA.swift
//
//
//  Created by Nanashi Li on 2023/09/24.
//

let authenticatorAppWelcomeText =
  "Please access the two-factor authentication application on your device in order to retrieve your authentication code and complete the identity verification process."
let smsMessageWelcomeText =
  "We have recently dispatched a message to you via SMS, containing your authentication code. Kindly input this code into the provided form below to authenticate your identity."

enum AuthenticationMode {
  /*
   * User should authenticate via a received text message.
   */
  case sms
  /*
   * User should open TOTP mobile application and obtain code.
   */
  case app
}

func getWelcomeMessage(type: AuthenticationMode) -> String {
  return type == .sms ? smsMessageWelcomeText : authenticatorAppWelcomeText
}
