//
//  ViewController.swift
//  WebSocketsTest
//
//  Created by Tim on 08.01.2021.
//

import UIKit
import Starscream
import SnapKit

class ViewController: UIViewController {
    lazy var loaderView: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.style = .large
        loader.color = .green
        return loader
    }()
    lazy var connectButton: UIButton = { [weak self] in
        let button = UIButton()
        button.setTitle("Connect to server", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.lightGray, for: .highlighted)
        button.setTitleColor(.black, for: .disabled)
        button.backgroundColor = .darkGray
        button.addTarget(self, action: #selector(connectToServer), for: .touchUpInside)
        button.layer.cornerRadius = 16
        return button
    }()
    lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = label.font.withSize(24)
        return label
    }()
    lazy var stopButton: UIButton = { [weak self] in
        let button = UIButton()
        button.setTitle("Stop", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.lightGray, for: .highlighted)
        button.backgroundColor = .darkGray
        button.addTarget(self, action: #selector(stopConnecting), for: .touchUpInside)
        button.layer.cornerRadius = 16
        self?.disableButton(button: button)
        return button
    }()
    lazy var shutdownPcButton: UIButton = { [weak self] in
        let button = UIButton()
        button.setTitle("Shutdown PC", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.darkGray, for: .highlighted)
        button.titleLabel?.font = .boldSystemFont(ofSize: 30)
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(shutdownPc), for: .touchUpInside)
        button.layer.cornerRadius = 16
        button.isHidden = true
        return button
    }()
    lazy var sleepPcButton: UIButton = { [weak self] in
        let button = UIButton()
        button.setTitle("Sleep PC", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.lightGray, for: .highlighted)
        button.titleLabel?.font = .boldSystemFont(ofSize: 30)
        button.backgroundColor = #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
        button.addTarget(self, action: #selector(sleepPc), for: .touchUpInside)
        button.layer.cornerRadius = 16
        button.isHidden = true
        return button
    }()
    
    var socket: WebSocket!
    var isConnected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configView()
        configWebSocket()
    }

    private func configView() {
        view.backgroundColor = .black
        view.addSubview(stopButton)
        stopButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalToSuperview().offset(50)
            make.right.equalToSuperview().offset(-50)
            make.height.equalTo(60)
        }
        view.addSubview(connectButton)
        connectButton.snp.makeConstraints { make in
            make.bottom.equalTo(stopButton.snp.top).offset(-20)
            make.left.equalTo(stopButton.snp.left)
            make.right.equalTo(stopButton.snp.right)
            make.height.equalTo(60)
        }
        view.addSubview(loaderView)
        loaderView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(loaderView.snp.centerY).offset(40)
        }
        view.addSubview(shutdownPcButton)
        shutdownPcButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(loaderView.snp.top).offset(20)
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(100)
        }
        view.addSubview(sleepPcButton)
        sleepPcButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(shutdownPcButton.snp.top).offset(-12)
            make.width.equalTo(shutdownPcButton)
            make.height.equalTo(shutdownPcButton)
        }
    }
    
    private func configWebSocket() {
        var request = URLRequest(url: URL(string: "ws://192.168.1.73:8080/")!)
        socket = WebSocket(request: request)
        socket.delegate = self
    }
    
    @objc func connectToServer() {
        loaderView.startAnimating()
        disableButton(button: connectButton)
        enableButton(button: stopButton)
        statusLabel.text = "Connecting..."
        socket.connect()
    }
    
    @objc func stopConnecting() {
        socket.disconnect()
        enableButton(button: connectButton)
        disableButton(button: stopButton)
        shutdownPcButton.isHidden = true
        sleepPcButton.isHidden = true
        loaderView.stopAnimating()
        statusLabel.text = "Stopped"
    }
    
    @objc func shutdownPc() {
        socket.write(string: "shutdown")
    }
    
    @objc func sleepPc() {
        socket.write(string: "sleep")
    }
    
    private func enableButton(button: UIButton) {
        button.alpha = 1
        button.isEnabled = true
    }
    
    private func disableButton(button: UIButton) {
        button.alpha = 0.5
        button.isEnabled = false
    }
    
}

extension ViewController: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            statusLabel.text = "Connected ✅"
            disableButton(button: connectButton)
            shutdownPcButton.isHidden = false
            sleepPcButton.isHidden = false
            loaderView.stopAnimating()
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            print("ping")
            break
        case .pong(_):
            print("pong")
            break
        case .viabilityChanged(let flag):
            print("viabilityChanged: \(flag)")
            break
        case .reconnectSuggested(let flag):
            print("reconnectSuggested: \(flag)")
            break
        case .cancelled:
            print("cancelled")
            isConnected = false
        case .error(let error):
            isConnected = false
            handleError(error)
        }
    }
    
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
    
}
