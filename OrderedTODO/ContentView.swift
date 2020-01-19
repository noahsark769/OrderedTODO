//
//  ContentView.swift
//  OrderedTODO
//
//  Created by Noah Gilmore on 12/26/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import SwiftUI
import SwiftUIX
import PureSwiftUI
import GRDB
import GRDBCombine
import Combine

struct Sheet<Content: View>: View {
    @Binding var showing: Bool
    let content: () -> Content
    @State private var translation: CGFloat = 0

    init(showing: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self._showing = showing
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .zIndex(1)
                .opacity(showing ? 0.2 : 0)
                .onTapGesture {
                    if self.showing {
                        withAnimation(.interactiveSpring()) {
                            self.showing = false
                        }
                    }
                }
            content()
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 400)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .opacity(showing ? 1 : 0)
                .offset(0, showing ? max(0, self.translation) : 100)
                .zIndex(2)
                .gesture(
                    DragGesture().onChanged { value in
                        self.translation = value.translation.height
                    }.onEnded { value in
                        let snapDistance: CGFloat = 200
                        guard abs(value.translation.height) > snapDistance else {
                            withAnimation(.interactiveSpring()) {
                                self.translation = 0
                            }
                            return
                        }
                        withAnimation(.interactiveSpring()) {
                            self.showing = false
                            self.translation = 0
                        }
                    }
                )
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView: View {
    @State var models: [ListModel] = []
    @State var isShowingAdd: Bool = false

    var addButton: some View {
        return Button(action: {
            withAnimation(.interactiveSpring()) {
                self.isShowingAdd.toggle()
            }
        }) {
            Image(systemName: "plus")
        }
    }

    var body: some View {
        ZStack {
            NavigationView {
                List(models) { model in
                    Text("\(model.name) (\(String(describing: model.id)))")
                }
                .navigationBarItems(trailing: self.addButton)
                .navigationBarTitle("Lists")
            }.zIndex(1)
            Sheet(showing: self.$isShowingAdd) {
                Button(action: {
                    var model = ListModel(name: "This my list", isDated: true)
                    try! DatabaseManager.shared.queue.write { db in
                        try! model.insert(db)
                    }
                    withAnimation(.interactiveSpring()) {
                        self.isShowingAdd = false
                    }
                }) {
                    Text("Add List")
                        .foregroundColor(Color(UIColor.systemBackground))
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
                }
            }.zIndex(3)
            self.addButton.zIndex(2)
        }
        .onReceive(
            ValueObservation
                .tracking(value: ListModel.all().fetchAll)
                .publisher(in: DatabaseManager.shared.queue)
                .catch { _ in Empty() }
        ) { value in
            self.models = value
        }
    }
}
