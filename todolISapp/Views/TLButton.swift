//
//  TLButton.swift
//  todolISapp
//
//  Created by Aiden on 30/5/25.
//

import SwiftUI

struct TLButton: View {
    let title: String
    let background: Color
    let action: ()->Void
    
    var body: some View {
        Button{
            // Logic
            action()
        }
        label: {
            ZStack{
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(background)
                
                Text(title)
                    .foregroundColor(Color.white).bold()
            }
        }
    }
}

#Preview {
    TLButton(title: "title", background: .blue){
        // action
    }
}
