//
//  PeripheralViewModel.swift
//  SensorAndBLE
//
//  Created by cmStudent on 2022/08/30.
//

import Foundation
import Combine
import CoreBluetooth

final class PeripheralViewModel: NSObject, ObservableObject {
    
    // MARK: BLE用 ーーーーーーーーーーーーーーーーーーー
    private var cancellables = Set<AnyCancellable>()
    var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic?
    var connectedCentral: CBCentral?
    var dataToSend = Data()
    var sendDataIndex: Int = 0
    
    @Published var textMessage = ""
    @Published var targetNumber = 0
    
    // MARK: アクションシート用　ーーーーーーーーーーーーー
    @Published var isShowActionSheet = false
    // 的の画面に遷移
    @Published var isShowCentral = false
    @Published var identifier = 0

    
    // MARK: センサー用 ーーーーーーーーーーーーーーーーー
    private let shared = MotionManager.shared
    @Published var roll = 0.0
    @Published var yaw = 0.0
    @Published var isSending = false
    
    override init() {
        super.init()
        
        $isSending
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.sendAction()
                (self.roll, self.yaw) = self.shared.startUpdates()
                self.textMessage = "\(self.roll)、\(self.yaw)、\(self.targetNumber)"
                
            }
            .store(in: &cancellables)
    }
    
    func tabValue(target: Int) {
        targetNumber = target
    }
    
    // 下か上かを判定するときに使う
    func changeMode(mode: Int) {
        if 1 == mode {
            identifier = mode
        } else {
            identifier = mode
        }
    }
    
    func setupPeripheralManager() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    func deinitPeripheralManager() {
        stopAction()
    }
    
    private func sendAction() {
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID],
                                               CBAdvertisementDataLocalNameKey: "TESTAPP"])
    }
    
    private func stopAction() {
        peripheralManager.stopAdvertising()
    }
    
    //  接続されたセントラルにデータを送信
    static var sendingEOM = false
    
    private func sendData() {
        
        guard let transferCharacteristic = transferCharacteristic else {
            return
        }
        
        // EOMを送信する必要があるかの確認
        if PeripheralViewModel.sendingEOM {
            // send it
            let didSend = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            // Did it send?
            if didSend {
                // 送信されたので、送信済みとしてマーク
                PeripheralViewModel.sendingEOM = false
                print("Sent: EOM")
            }
            // 送信されなかったので、終了してsendDataを呼び出すのを待つ
            return
        }
        
        // EOMを送信しないからデータを送信
        if sendDataIndex >= dataToSend.count {
            return
        }
        
        // データが残っているからコールバックが失敗するまで送信するか、終了
        var didSend = true
        while didSend {
            
            var amountToSend = dataToSend.count - sendDataIndex
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            // 欲しいデータをコピー
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            // 送信
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            // うまくいかなかった時はドロップアウトしてコールバックを待つ
            if !didSend {
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            print("Sent \(chunk.count) bytes: \(String(describing: stringFromData))")
            
            // 送信されたのでインデックスを更新
            sendDataIndex += amountToSend
            if sendDataIndex >= dataToSend.count {
                
                // 送信に失敗したとき、次回に送信するように設定
                PeripheralViewModel.sendingEOM = true
                
                // 送信する
                let eomSent = peripheralManager.updateValue("EOM".data(using: .utf8)!,
                                                            for: transferCharacteristic, onSubscribedCentrals: nil)
                
                if eomSent {
                    // 送信されたので、すべて終了
                    PeripheralViewModel.sendingEOM = false
                    print("Sent: EOM")
                }
                return
            }
        }
    }
    
    private func setupPeripheral() {
        
        // CBMutableCharacteristicからStart
        let transferCharacteristic = CBMutableCharacteristic(type: TransferService.characteristicUUID,
                                                             properties: [.notify, .writeWithoutResponse],
                                                             value: nil,
                                                             permissions: [.readable, .writeable])
        
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // サービスに追加
        transferService.characteristics = [transferCharacteristic]
        
        // 周辺機器マネージャに追加
        peripheralManager.add(transferService)
        
        // 保存しておく
        self.transferCharacteristic = transferCharacteristic
        
    }
}

extension PeripheralViewModel: CBPeripheralManagerDelegate {
    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
        case .poweredOn:
            // 周辺機器との連携を開始
            print("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            print("CBManager is not powered on")
            return
        case .resetting:
            print("CBManager is resetting")
            return
        case .unauthorized:
            print("Unexpected authorization")
            return
        case .unknown:
            print("CBManager state is unknown")
            return
        case .unsupported:
            print("Bluetooth is not supported on this device")
            return
        @unknown default:
            print("A previously unknown peripheral manager state occurred")
            return
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central subscribed to characteristic")
        
        // データを取得する
        if let message = textMessage.data(using: .utf8) {
            dataToSend = message
        }
        
        // インデックスをリセット
        sendDataIndex = 0
        
        connectedCentral = central
        
        // 送信開始
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unsubscribed from characteristic")
        connectedCentral = nil
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for aRequest in requests {
            guard let requestValue = aRequest.value,
                  let stringFromData = String(data: requestValue, encoding: .utf8) else {
                continue
            }
            
            print("Received write request of \(requestValue.count) bytes: \(stringFromData)")
            textMessage = stringFromData
            
            print(textMessage)
        }
    }
}
