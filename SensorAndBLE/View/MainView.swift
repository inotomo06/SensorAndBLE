//
//  Main.swift
//  SensorAndBLE
//
//  Created by cmStudent on 2022/09/09.
//

import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()
    var body: some View {
        VStack {
            Button {
                viewModel.isShowActionSheet = true
            } label: {
                Text("射的を始める")
            }
        }
        .onAppear() {
            viewModel.isShowActionSheet = true
        }
        .actionSheet(isPresented: $viewModel.isShowActionSheet) {
            ActionSheet(
                title: Text("Changing settings"),
                buttons: [
                    .default(Text("このデバイスをマトにする"), action: {
                        // アニメーションをなくすやつ
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            viewModel.changeMode(mode: 1) // 下か上かの判定
                            viewModel.isShowCentral.toggle() // 画面遷移
                        }
                    }),
                    .default(Text("このデバイスを銃にする"), action: {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            viewModel.changeMode(mode: 2) // 下か上かの判定
                            viewModel.isShowCentral.toggle() // 画面遷移
                        }
                    }),
                    .cancel(Text("Cencel"))
                ])
        }
        .fullScreenCover(isPresented: $viewModel.isShowCentral){
            if 1 == viewModel.identifier {
                CentralView()
            } else if 2 == viewModel.identifier {
                PeripheralView()
            }
        }
    }
}


struct Main_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
