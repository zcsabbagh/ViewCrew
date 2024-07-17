//
//  WebViewNetflixSignIn.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/15/24.
//

import SwiftUI
import WebKit

struct WebViewWrapper: UIViewControllerRepresentable {
    @ObservedObject var koodosIntegration: KoodosViewModel
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> WebViewController {
        let controller = WebViewController()
        controller.onDismiss = onDismiss
        controller.koodosIntegration = koodosIntegration
        return controller
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {}
}

class WebViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var onDismiss: (() -> Void)?
    var koodosIntegration: KoodosViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contentController = WKUserContentController()
        contentController.add(self, name: "loginHandler")
        contentController.add(self, name: "profileHandler")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if let url = URL(string: "https://www.netflix.com/ProfilesGate") {
            webView.load(URLRequest(url: url))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString.contains("login") == true {
            injectJavaScript(webView: webView)
        } else if webView.url?.absoluteString.contains("ProfilesGate") == true {
            injectJavaScriptForProfilesGate(webView: webView)
        } 
    }

    func injectJavaScriptForProfilesGate(webView: WKWebView) {
        let jsScript = """
        (function() {
            function getCookies() {
                var cookies = document.cookie.split('; ');
                var netflixId = cookies.find(row => row.startsWith('NetflixId=')).split('=')[1];
                var secureNetflixId = cookies.find(row => row.startsWith('SecureNetflixId=')).split('=')[1];
                
                window.webkit.messageHandlers.profileHandler.postMessage({
                    netflixId: netflixId,
                    secureNetflixId: secureNetflixId
                });
            }

            function addProfileLinkListeners() {
                var profileLinks = document.querySelectorAll('a.profile-link');
                profileLinks.forEach(function(link) {
                    link.addEventListener('click', function(event) {
                        event.preventDefault();
                        var url = new URL(this.href);
                        var profileId = url.searchParams.get('tkn');
                        if (profileId) {
                            console.log("Profile ID clicked: " + profileId);
                            window.webkit.messageHandlers.profileHandler.postMessage({profileId: profileId});
                        }
                    });
                });
            }

            getCookies();
            addProfileLinkListeners();

            // Observer to handle dynamically loaded content
            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.type === 'childList') {
                        addProfileLinkListeners();
                    }
                });
            });

            observer.observe(document.body, { childList: true, subtree: true });
        })();
        """
        
        webView.evaluateJavaScript(jsScript) { result, error in
            if let error = error {
                print("Error injecting JavaScript for ProfilesGate: \(error.localizedDescription)")
            } else {
                print("JavaScript injected successfully for ProfilesGate")
            }
        }
    }

    func injectJavaScript(webView: WKWebView) {
        let jsScript = """
        (function() {
            function addEventListenerToSubmitButton() {
                var submitButton = document.querySelector('button[type="submit"]');
                var emailField = document.querySelector('input[name="userLoginId"]');
                var passwordField = document.querySelector('input[name="password"]');
        
                if (submitButton && emailField && passwordField && !submitButton.dataset.listenerAdded) {
                    submitButton.dataset.listenerAdded = 'true';
                    submitButton.addEventListener('click', function() {
                        var email = emailField.value;
                        var password = passwordField.value;
                        var authURL = window.netflix.reactContext.models.userInfo.data.authURL;
                        window.webkit.messageHandlers.loginHandler.postMessage({email: email, password: password, authURL: authURL});
                    });
                }
            }
        
            document.addEventListener('DOMContentLoaded', function() {
                addEventListenerToSubmitButton();
            });
        
            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    addEventListenerToSubmitButton();
                });
            });
            observer.observe(document, { childList: true, subtree: true });
        
            window.addEventListener('load', function() {
                addEventListenerToSubmitButton();
            });
        
            var pageNavigationObserver = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    addEventListenerToSubmitButton();
                });
            });
            pageNavigationObserver.observe(document, { childList: true, subtree: true });
        })();
        """
        
        webView.evaluateJavaScript(jsScript) { result, error in
            if let error = error {
                print("Error injecting JavaScript: \(error.localizedDescription)")
            } else {
                print("JavaScript injected successfully for Login Page")
            }
        }
    }
}

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "loginHandler" {
            if let messageBody = message.body as? [String: String],
            let email = messageBody["email"],
            let password = messageBody["password"],
            let authURL = messageBody["authURL"] {
                print("Email: \(email)")
                print("Password: \(password)")
                print("AuthURL: \(authURL)")
                koodosIntegration?.updateLoginInfo(email: email, password: password, authURL: authURL)
            }
        } else if message.name == "profileHandler" {
            if let messageBody = message.body as? [String: String] {
                let netflixId = messageBody["netflixId"]
                let secureNetflixId = messageBody["secureNetflixId"]
                let profileId = messageBody["profileId"]
                
                if let netflixId = netflixId, let secureNetflixId = secureNetflixId {
                    print("NetflixId: \(netflixId)")
                    print("SecureNetflixId: \(secureNetflixId)")
                    koodosIntegration?.netflixId = netflixId
                    koodosIntegration?.secureNetflixId = secureNetflixId
  
                }

                if let profileId = profileId {
                    print("Profile ID clicked: \(profileId)")
                    koodosIntegration?.updateProfileInfo(profileId: profileId, netflixId: netflixId, secureNetflixId: secureNetflixId)
                    DispatchQueue.main.async {
                    self.koodosIntegration?.fetchCountry { country in
                        print("Country: \(country)")
                        self.koodosIntegration?.country = country
                        self.koodosIntegration?.signInReady = true
                        self.onDismiss?()
                        }
                }
                

            }
            }
        }
    }
}
