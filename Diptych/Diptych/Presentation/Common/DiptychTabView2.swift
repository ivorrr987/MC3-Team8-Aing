//
//  DiptychTabView2.swift
//  Diptych
//
//  Created by Koo on 2023/07/20.
//

import SwiftUI

struct DiptychTabView2: View {
    ///Property
    @State var currentTab : Int = 0
    @Namespace var namespace
    var tabBarTitle: [String] = ["오늘의 딥틱", "보관함", "프로필"]
    var selectedIcons: [String] = ["imgTodayDiptychTabSelected", "imgArchiveTabSelected", "imgProfileTabSelected"]
    var UnselectedIcons: [String] = ["imgTodayDiptychTab", "imgArchiveTab", "imgProfileTab"]
    
    var body: some View {
        NavigationView{
            VStack(spacing: 0){
                
                /// 각 뷰로 이동
                VStack(spacing: 0){
                    if currentTab == 0 {
                        TodayDiptychView()
                    }
                    else if currentTab == 1 {
                        ArchiveTabView(currentTab: currentTab)
                    }
                    else if currentTab == 2 {
                        ProfileView()
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
                
                /// 하단 탭바
                HStack(spacing: 90) {
                    ForEach(tabBarTitle.indices, id: \.self) { index in
                        let title = tabBarTitle[index]
                        let icon1 = selectedIcons[index]
                        let icon2 = UnselectedIcons[index]
                        
                        Button {
                            currentTab = index
                        } label: {
                            DiptychTabBarItem(isSelected: currentTab == index, title: title,
                                              selectedIcon: icon1, UnselectedIcon: icon2)
                        }//】 Button
                        .buttonStyle(.plain)
                    }//】 Loop
                }//】 HStack
                .frame(maxWidth: .infinity)
                .frame(height: 100)
//                .padding(.horizontal,30)
                .background(Color.white)
                
            }//】 VStack
            .ignoresSafeArea()
        }//】 Navigation
    }//】 Body
}


struct DiptychTabBarItem: View {
    
    ///Property
    var isSelected: Bool
    var title: String
    var selectedIcon: String
    var UnselectedIcon: String
    
    var body: some View {
        
            VStack(spacing: 0) {
               
                VStack(spacing: 0) {
                    /// 탭바 아이콘
                    if isSelected{
                        Image(selectedIcon)
                    } else {
                        Image(UnselectedIcon)
                    }
                    
                }//】 VStack
                .padding(.bottom,5)
                
                VStack(spacing: 0){
                    /// 탭바 텍스트
                    if isSelected{
                        Text(title)
                            .font(.system(size:12, weight: .medium))
                            
                    } else {
                        Text(title)
                            .font(.system(size:12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }//】 VStack
               
                
            }//】 VStack
            .offset(y:-7)
            .animation(.spring(), value: isSelected) // 애니메이션 타입
    }//】 Body
}


struct DiptychTabView2_Previews: PreviewProvider {
    static var previews: some View {
        DiptychTabView2()
    }
}
