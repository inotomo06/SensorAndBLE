//
//  CentralViewModel.swift
//  SensorAndBLE
//
//  Created by cmStudent on 2022/08/30.
//

import Foundation
import CoreBluetooth

final class CentralViewModel: NSObject, ObservableObject {
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var transferCharacteristic: CBCharacteristic?
    var writeIterationsComplete = 0
    var connectionIterationsComplete = 0
    var defaultIterations = 500     // テストケースに応じてこの値を変更する
    var data = Data()
    
    // MARK: 当たり判定 ーーーーーーーーーーーーー
    var textMessage: [String] = []
    @Published var textRoll = 0.0
    @Published var textYaw = 0.0
    @Published var text = ""
    @Published var image = "sheringford"
    var dataAcquired = ""
    @Published var target1 = "232277"
    @Published var target2 = "232285"
    @Published var target3 = "232297"
    @Published var target4 = "22785727"
    @Published var target5 = "オッドアイ猫"
    
    // MARK: アクションシート ーーーーーーーーーーー
    @Published var isShowActionSheet = false
    // 銃の画面に遷移
    @Published var isShowPeripheral = false
    @Published var identifier = 0
    
    // 下か上かを判定するときに使う
    func changeMode(mode: Int) {
        if 1 == mode {
            identifier = mode
        } else {
            identifier = mode
        }
    }
    
    func resetImage() {
        target1 = "232277"
        target2 = "232285"
        target3 = "232297"
        target4 = "22785727"
        target5 = "オッドアイ猫"
        
        textMessage[0] = "0.0"
        textMessage[1] = "0.0"
    }
    
    // 当たり判定用
    private func judgement(targetNum: Int) {
        
        let roll = Double(textMessage[0])
        let yaw = Double(textMessage[1])
        
        if roll ?? 0.0 <= -1.20 && roll ?? 0.0 >= -1.40 && yaw ?? 0.0 <= -0.60 && yaw ?? 0.0 >= -0.80 {
            switch targetNum {
            case 0:
                target1 = ""
                
            case 1:
                target2 = ""
                
            case 2:
                target3 = ""
                
            case 3:
                target4 = ""
                
            default:
                target5 = ""
            }
//        } else if (roll ?? 0.0 < -1.4 && roll ?? 0.0 >= -1.45) || (roll ?? 0.0 <= -1.15 && roll ?? 0.0 > -1.2) {
//            target5 = "user"
//        } else if (yaw ?? 0.0 <= -0.55 && yaw ?? 0.0 > -0.60) || (yaw ?? 0.0 < -0.80 && yaw ?? 0.0 >= -0.85) {
//            target5 = "user"
        } else if roll == 0.0 && yaw == 0.0 {
            // 何もしない
        } else {
            target5 = "user"
        }
    }
    
    func setupCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    func deinitCentralManager() {
        centralManager.stopScan()
        defaultIterations = 0
        print("Scanning stopped")
        
        data.removeAll(keepingCapacity: false)
    }
    
    private func retrievePeripheral() {
        
        let connectedPeripherals: [CBPeripheral] = (centralManager.retrieveConnectedPeripherals(withServices: [TransferService.serviceUUID]))
        
        print("Found connected Peripherals with transfer service: \(connectedPeripherals)")
        
        if let connectedPeripheral = connectedPeripherals.last {
            print("Connecting to peripheral \(connectedPeripheral)")
            self.discoveredPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
        } else {
            // We were not connected to our counterpart, so start scanning
            centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    private func cleanup() {
        // つながっていないときは何もしない
        guard let discoveredPeripheral = discoveredPeripheral,
              case .connected = discoveredPeripheral.state else { return }
        
        for service in (discoveredPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == TransferService.characteristicUUID && characteristic.isNotifying {
                    // 通知されるから配信を停止
                    self.discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        // ここまでくれば、接続はされている。が、購読はされてないから切断するだけ
        centralManager.cancelPeripheralConnection(discoveredPeripheral)
    }
    
    private func writeData() {
        
        guard let discoveredPeripheral = discoveredPeripheral,
              let transferCharacteristic = transferCharacteristic else {
            return
        }
        
        // 繰り返し回数が完了し、周辺機器がより多くのデータを受け入れることができるかどうかを確認
        while writeIterationsComplete < defaultIterations && discoveredPeripheral.canSendWriteWithoutResponse {
            
            writeIterationsComplete += 1
            
        }
        
        if writeIterationsComplete == defaultIterations {
            // 購読を中止
            discoveredPeripheral.setNotifyValue(false, for: transferCharacteristic)
        }
    }
}

extension CentralViewModel: CBCentralManagerDelegate {
    
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            print("CBManager is powered on")
            retrievePeripheral()
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
            print("A previously unknown central manager state occurred")
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        guard RSSI.intValue >= -50
        else {
            print("Discovered perhiperal not in expected range, at \(RSSI.intValue)")
            return
        }
        
        print("Discovered \(String(describing: peripheral.name)) at \(RSSI.intValue)")
        
        if discoveredPeripheral != peripheral {
            
            // CoreBluetoothがそれを取り除くことがないように、周辺機器のを保存。
            discoveredPeripheral = peripheral
            
            // 周辺機器との接続
            print("Connecting to perhiperal \(peripheral)")
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). \(String(describing: error))")
        cleanup()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected")
        
        // スキャンを停止
        centralManager.stopScan()
        print("Scanning stopped")
        
        // 繰り返し情報を設定する
        connectionIterationsComplete += 1
        writeIterationsComplete = 0
        
        // すでに持っているかもしれないデータをクリアする
        data.removeAll(keepingCapacity: false)
        
        // ディスカバリーコールバックの取得を確認する
        peripheral.delegate = self
        
        // 自分のUUIDと一致するサービスのみを検索する
        peripheral.discoverServices([TransferService.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Perhiperal Disconnected")
        discoveredPeripheral = nil
        
        // 接続が切れたら、もう一度スキャンを始める
        if connectionIterationsComplete < defaultIterations {
            retrievePeripheral()
        } else {
            print("Connection iterations completed")
        }
    }
}

extension CentralViewModel: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        for service in invalidatedServices where service.uuid == TransferService.serviceUUID {
            print("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([TransferService.serviceUUID])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            cleanup()
            return
        }
        
        // 複数のサービスがある場合に備えて、新しく満たされた peripheral.services 配列をループする
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // エラーがある場合は対処する
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            cleanup()
            return
        }
        
        // もう一度、配列の中をループして、正しいかどうかチェック
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
            
            transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // エラーの対処
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        print("Received \(characteristicData.count) bytes: \(stringFromData)")
        
        // メッセージの終了トークンを受け取ったか
        if stringFromData == "EOM" {
            
            dataAcquired = String(data: data, encoding: .utf8) ?? ""
            textMessage = dataAcquired.components(separatedBy: CharacterSet(charactersIn: "、"))
            
            print("----------------------------------------")
            print("roll = " + textMessage[0])
            print("yaw = " + textMessage[1])
            
            let roll = Double(textMessage[0])
            let yaw = Double(textMessage[1])
            
            print("doubleROLL = \(roll ?? 0.0)")
            print("doubleYAW = \(yaw ?? 0.0)")
            print("----------------------------------------")
            
            judgement(targetNum: Int(textMessage[2]) ?? 0)
            
            textRoll = roll ?? 0.0
            textYaw = yaw ?? 0.0
            
            // テストデータの書き込み
            writeData()
        } else {
            // そうでない場合は以前に受け取ったデータに追加する
            data.append(characteristicData)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // エラーの対処
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }
        
        // 転送でない場合は終了する
        guard characteristic.uuid == TransferService.characteristicUUID else { return }
        
        if characteristic.isNotifying {
            // お知らせを開始
            print("Notification began on \(characteristic)")
        } else {
            // 通知が停止してるから、周辺機器との接続を解除
            print("Notification stopped on \(characteristic). Disconnecting")
            cleanup()
        }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("Peripheral is ready, send data")
    }
}
