//
//  CentralView.swift
//  SensorAndBLE
//
//  Created by cmStudent on 2022/08/30.
//

import SwiftUI

struct CentralView: View {
    @StateObject private var viewModel = CentralViewModel()
    var body: some View {
        
        ZStack {
            //            Image("縁日の屋台（夜）")
            //                .resizable()
            //                .aspectRatio(contentMode: .fill)
            //                .ignoresSafeArea()
            //                .blur(radius: 10.0)
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                Spacer()
                
                //                Rectangle()
                //                    .frame(width: UIScreen.main.bounds.width, height: 83)
                //                    .foregroundColor(Color.red)
                Image("名称未設定")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.height / 1000 : 100)
                    .ignoresSafeArea()
            }
            
            VStack {
                Spacer()
                Spacer()
                HStack {
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    Button {
                        viewModel.resetImage()
                    } label: {
                        Text("リセット")
                    }
                    Spacer()
                    
                    Button {
                        viewModel.isShowActionSheet.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .actionSheet(isPresented: $viewModel.isShowActionSheet) {
                        ActionSheet(
                            title: Text("Changing settings"),
                            buttons: [
                                .default(Text("このデバイスを銃にする"), action: {
                                    // アニメーションをなくすやつ
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        viewModel.textMessage[0] = "0.0"
                                        viewModel.textMessage[1] = "0.0"
                                        viewModel.changeMode(mode: 1)
                                        viewModel.isShowPeripheral.toggle()
                                    }
                                }),
                                .default(Text("終わる"), action: {
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        viewModel.textMessage[0] = "0.0"
                                        viewModel.textMessage[1] = "0.0"
                                        viewModel.changeMode(mode: 2)
                                        viewModel.isShowPeripheral.toggle()
                                    }
                                }),
                                .cancel(Text("Cencel"))
                            ])
                    }
                    .fullScreenCover(isPresented: $viewModel.isShowPeripheral){
                        if 1 == viewModel.identifier {
                            PeripheralView()
                        } else if 2 == viewModel.identifier {
                            MainView()
                        }
                    }
                    
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(viewModel.target1)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        
                        Spacer()
                        Image(viewModel.target2)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        Spacer()
                        Image(viewModel.target3)
                        
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        Spacer()
                        Image(viewModel.target4)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        Spacer()
                    }
                    
                    Rectangle()
                        .frame(width: UIScreen.main.bounds.width, height: 40)
                        .foregroundColor(Color.red)
                    
                    Spacer()
                    
                }
            }
        }
        .onAppear(perform: viewModel.setupCentralManager)
        .onDisappear(perform: viewModel.deinitCentralManager)
    }
}

struct CentralView_Previews: PreviewProvider {
    static var previews: some View {
        CentralView()
    }
}
