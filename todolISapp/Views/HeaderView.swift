//
//  HeaderView.swift
//  todolISapp
//
//  Created by Aiden on 30/5/25.
//

import SwiftUI

struct HeaderView: View {
    let title:String
    let subtitle:String
    let angle: Double
    let background:Color
    let paddingTop: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .foregroundColor(background)
                .rotationEffect(Angle(degrees: angle))
            
            VStack {
                Text(title).font(.system(size: 50)).foregroundColor(Color.white).bold()
                Text(subtitle).font(.system(size: 30)).foregroundColor(Color.white)
            }
            .padding(.top, paddingTop)
        }.frame(width: UIScreen.main.bounds.width * 2, height: 350)
            .offset(y:-150)
    }
}

#Preview {
    HeaderView(title: "title", subtitle: "subtitle", angle: 15, background: .blue, paddingTop: 80)
}
