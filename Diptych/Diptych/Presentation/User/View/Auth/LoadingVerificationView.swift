//
//  LoadingVerificationView.swift
//  Diptych
//
//  Created by HAN GIBAEK on 2023/07/21.
//

import SwiftUI

struct LoadingVerificationView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        ZStack {
            Color.offWhite
            VStack {
                Spacer()
                    .frame(height: 124)
                Text("인증 메일을 확인해주세요")
                    .font(.pretendard(.light, size: 28))
                Spacer()
                    .frame(height: 40)
                Text("입력하신 이메일로 인증 링크를 보냈습니다\n링크 클릭 후 앱으로 돌아와 주세요")
                    .font(.pretendard(.light, size: 18))
                    .foregroundColor(.darkGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                Spacer()
                Button {
                    Task {
                        await userViewModel.checkEmailVerification3()
                    }
                } label: {
                    Text("인증 완료")
                        .frame(width: UIScreen.main.bounds.width-30, height:  60)
                        .background(Color.offBlack)
                        .foregroundColor(.offWhite)
                }
                Button {
                    Task {
                        try await userViewModel.sendEmailVerification()
                    }
                } label: {
                    Text("인증 메일 다시 보내기")
                        .frame(width: UIScreen.main.bounds.width-30, height:  60)
                        .background(Color.offWhite)
                        .foregroundColor(.offBlack)
                        .border(Color.offBlack)
                }
                
                Spacer()
                    .frame(height: 47)
            }
            .padding([.leading, .trailing], 15)
        }
        .ignoresSafeArea()
    }
}

struct LoadingVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingVerificationView()
    }
}
