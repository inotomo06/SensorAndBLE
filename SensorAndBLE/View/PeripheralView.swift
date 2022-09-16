//
//  PeripheralView.swift
//  SensorAndBLE
//
//  Created by cmStudent on 2022/08/30.
//

import SwiftUI

struct PeripheralView: View {
    @StateObject private var viewModel = PeripheralViewModel()
    @State private var tabNumber = 0
    var body: some View {
        
        ZStack {
            Color.white
            
            ZStack {
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
                        Spacer()
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
                                    .default(Text("このデバイスをマトにする"), action: {
                                        // アニメーションをなくすやつ
                                        var transaction = Transaction()
                                        transaction.disablesAnimations = true
                                        withTransaction(transaction) {
                                            viewModel.changeMode(mode: 1)
                                            viewModel.isShowCentral.toggle()
                                        }
                                    }),
                                    .default(Text("終わる"), action: {
                                        var transaction = Transaction()
                                        transaction.disablesAnimations = true
                                        withTransaction(transaction) {
                                            viewModel.changeMode(mode: 2)
                                            viewModel.isShowCentral.toggle()
                                        }
                                    }),
                                    .cancel(Text("Cencel"))
                                ])
                        }
                        .fullScreenCover(isPresented: $viewModel.isShowCentral){
                            if 1 == viewModel.identifier {
                                CentralView()
                            } else if 2 == viewModel.identifier {
                                MainView()
                            }
                        }
                        
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.largeTitle)
                            .padding()
                            .onTapGesture {
                                if tabNumber != 0 {
                                    tabNumber -= 1
                                }
                            }
                        
                        VStack(spacing: 0) {
                            // 選択用の的たち
                            TabView(selection: $tabNumber) {
                                Image("232277")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100, height: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100)
                                    .tag(0)
                                Image("232285")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100,
                                           height: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100)
                                    .tag(1)
                                Image("232297")
                                
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100,
                                           height: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100)
                                    .tag(2)
                                Image("22785727")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100,
                                           height: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100)
                                    .tag(3)
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .transition(.slide)
                            .animation(.easeInOut)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.largeTitle)
                            .padding()
                            .onTapGesture {
                                if tabNumber != 3 {
                                    tabNumber += 1
                                }
                            }
                    }
                    .padding(.horizontal, 30)
                }
                
                
                Image("しののんを撃つ 2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
        }
        .onAppear(perform: viewModel.setupPeripheralManager)
        .onDisappear(perform: viewModel.deinitPeripheralManager)
        .onTapGesture {
            viewModel.tabValue(target: tabNumber)
            viewModel.isSending = true
            print(viewModel.isSending)
        }
        .ignoresSafeArea()
    }
}



struct PeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        PeripheralView()
    }
}
