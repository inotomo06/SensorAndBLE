//
//  MainViewModel.swift
//  SensorAndBLE
//
//  Created by cmStudent on 2022/09/09.
//

import Foundation

final class MainViewModel: ObservableObject {
    
    // 画面遷移
    @Published var isShowCentral = false
    // mode変更のActionSheet
    @Published var isShowActionSheet = false
    // アクションシートのメッサージのどちらが選択されたかを保存識別するやつ
    @Published var identifier = 0

    // 下か上かを判定するときに使う
    func changeMode(mode: Int) {
        if 1 == mode {
            identifier = mode
//            isShowCentral.toggle() // 画面遷移
        } else {
            identifier = mode
//            isShowCentral.toggle() // 画面遷移
        }
    }
}

