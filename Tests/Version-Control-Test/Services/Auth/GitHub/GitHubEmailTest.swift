//
//  GitHubEmailTest.swift
//
//
//  Created by Tihan-Nico Paxton on 2023/09/25.
//

import Foundation
import XCTest
import Version_Control

class GitHubEmailTest: XCTestCase {
    
    // Helper method to create an Account object for testing
    func createAccount(withEmails emails: [IAPIEmail]) -> Account {
        return Account(login: "janedoe",
                       endpoint: "",
                       token: "",
                       emails: emails,
                       avatarURL: "",
                       id: 12345,
                       name: "Jane Doe",
                       plan: "free")
    }
    
    // Helper method to create an Email object for testing
    func createEmail(email: String,
                     primary: Bool = false,
                     visibility: EmailVisibility) -> IAPIEmail {
        return IAPIEmail(email: email,
                         verified: true,
                         primary: primary,
                         visibility: visibility)
    }
    
    func testLookupPreferredEmailWithPublicEmails() {
        let publicEmail1 = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .public)
        let publicEmail2 = createEmail(email: "janedoe2@auroraeditor.com", visibility: .public)
        let account = createAccount(withEmails: [publicEmail1, publicEmail2])
        let result = GitHubEmail().lookupPreferredEmail(account: account)
        XCTAssertEqual(result, "janedoe@auroraeditor.com")
    }
    
    func testLookupPreferredEmailWithNoPublicEmails() {
        let privateEmail1 = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .private)
        let privateEmail2 = createEmail(email: "user2@private.com", visibility: .private)
        let account = createAccount(withEmails: [privateEmail1, privateEmail2])
        let result = GitHubEmail().lookupPreferredEmail(account: account)
        XCTAssertEqual(result, "janedoe@auroraeditor.com")
    }
    
    func testLookupPreferredEmailWithStealthEmail() {
        let stealthEmail = createEmail(email: "user@stealth.com", visibility: .null)
        let account = createAccount(withEmails: [stealthEmail])
        let result = GitHubEmail().lookupPreferredEmail(account: account)
        XCTAssertEqual(result, "user@stealth.com")
    }
    
    // MARK: - Email Visibility
    
    func testIsEmailPublicWithPublicVisibility() {
        let email = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .public)
        let result = GitHubEmail().isEmailPublic(email: email)
        XCTAssertTrue(result)
    }
    
    func testIsEmailPublicWithNullVisibility() {
        let email = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .null)
        let result = GitHubEmail().isEmailPublic(email: email)
        XCTAssertTrue(result)
    }
    
    func testIsEmailPublicWithPrivateVisibility() {
        let email = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .private)
        let result = GitHubEmail().isEmailPublic(email: email)
        XCTAssertFalse(result)
    }
    
    // MARK: - Stealth Email
    
    func testGetStealthEmailHostForEndpoint() {
        let emailHost = GitHubEmail().getStealthEmailHostForEndpoint()
        XCTAssertEqual(emailHost, "users.noreply.github.com")
    }
    
    func testGetLegacyStealthEmailForUser() {
        let login = "janedoe"
        let expectedEmail = "janedoe@users.noreply.github.com"
        let legacyEmail = GitHubEmail().getLegacyStealthEmailForUser(login: login)
        XCTAssertEqual(legacyEmail, expectedEmail)
    }
    
    func testGetStealthEmailForUser() {
        let userId = 12345
        let login = "janedoe"
        let expectedEmail = "12345+janedoe@users.noreply.github.com"
        let stealthEmail = GitHubEmail().getStealthEmailForUser(id: userId, login: login)
        XCTAssertEqual(stealthEmail, expectedEmail)
    }
    
    // MARK: - Attributable Emails
    
    func testIsAttributableEmailForWithEmailInAccountEmails() {
        let publicEmail1 = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .public)
        let githubAccount = createAccount(withEmails: [publicEmail1])
        let emailToCheck = "janedoe@auroraeditor.com"
        let isAttributable = GitHubEmail().isAttributableEmailFor(account: githubAccount, email: emailToCheck)
        XCTAssertTrue(isAttributable)
    }
    
    func testIsAttributableEmailForWithGeneratedStealthEmail() {
        let publicEmail1 = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .public)
        let githubAccount = createAccount(withEmails: [publicEmail1])
        let emailToCheck = "12345+janedoe@users.noreply.github.com"
        let isAttributable = GitHubEmail().isAttributableEmailFor(account: githubAccount, email: emailToCheck)
        XCTAssertTrue(isAttributable)
    }
    
    func testIsAttributableEmailForWithGeneratedLegacyStealthEmail() {
        let publicEmail1 = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .public)
        let githubAccount = createAccount(withEmails: [publicEmail1])
        let emailToCheck = "janedoe@users.noreply.github.com"
        let isAttributable = GitHubEmail().isAttributableEmailFor(account: githubAccount, email: emailToCheck)
        XCTAssertTrue(isAttributable)
    }
    
    func testIsAttributableEmailForWithNonAttributableEmail() {
        let publicEmail1 = createEmail(email: "janedoe@auroraeditor.com", primary: true, visibility: .public)
        let githubAccount = createAccount(withEmails: [publicEmail1])
        let emailToCheck = "random@auroraeditor.com"
        let isAttributable = GitHubEmail().isAttributableEmailFor(account: githubAccount, email: emailToCheck)
        XCTAssertFalse(isAttributable)
    }
}
