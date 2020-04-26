//
//  ImageView.swift
//  HLApp
//
//  Created by Роман on 18.03.2020.
//  Copyright © 2020 destplay. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct DetailImageView: View {
    @ObservedObject var imageLoader: ImageLoader
    @State var image: UIImage = UIImage()

    init(withURL url:String) {
        imageLoader = ImageLoader(urlString:url)
    }
    
    var body: some View {
        VStack {
            Image(uiImage: imageLoader.data != nil ? UIImage(data:imageLoader.data!)! : UIImage())
                .resizable()
                .scaledToFit()
        }
    }
}

@available(iOS 13.0, *)
struct ZoomImageView: View {
    @ObservedObject var imageLoader: ImageLoader
    
    @State var image: UIImage = UIImage()
    @State private var scale: CGFloat = 1.0
    @State private var isTappet: Bool = false
    @State private var pointTappet: CGPoint = CGPoint.zero
    @State private var draggedSize: CGSize = CGSize.zero
    @State private var previusDragged: CGSize = CGSize.zero

    init(withURL url:String) {
        self.imageLoader = ImageLoader(urlString:url)
    }
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                Image(uiImage: self.imageLoader.data != nil ? UIImage(data: self.imageLoader.data!)! : UIImage())
                    .resizable()
                    .scaledToFit()
                    .offset(x: self.draggedSize.width, y: self.draggedSize.height)
                    .scaleEffect(self.scale)
                    .scaleEffect(self.isTappet ? 2 : 1, anchor: UnitPoint(x: self.pointTappet.x / geo.frame(in: .global).maxX, y: self.pointTappet.y / geo.frame(in: .global).maxY))
                    .gesture(TapGesture(count: 2)
                    .onEnded {
                        self.isTappet = !self.isTappet
                    })
                    .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        self.pointTappet = value.startLocation
                        self.draggedSize = CGSize(width: value.translation.width + self.previusDragged.width, height: value.translation.height + self.previusDragged.height)
                    }
                    .onEnded { value in
                        self.draggedSize = CGSize(width: value.translation.width + self.previusDragged.width, height: value.translation.height + self.previusDragged.height)
                        let offsetWidth = (geo.frame(in: .global).maxX * self.scale - geo.frame(in: .global).maxX) / 2
                        let newDraggedWidth = self.draggedSize.width * self.scale
                        if (newDraggedWidth > offsetWidth) {
                            self.draggedSize = CGSize(width: offsetWidth / self.scale, height: value.translation.height + self.previusDragged.height)
                        } else if (newDraggedWidth < -offsetWidth) {
                            self.draggedSize = CGSize(width: -offsetWidth / self.scale, height: value.translation.height + self.previusDragged.height)
                        } else {
                            self.draggedSize = CGSize(width: value.translation.width + self.previusDragged.width, height: value.translation.height + self.previusDragged.height)
                        }
                        self.previusDragged = self.draggedSize
                    }
                )
                .gesture(MagnificationGesture()
                    .onChanged { value in
                        self.scale = value.magnitude
                    }
                    .onEnded { value in
                        if value.magnitude < 1.0 {
                            self.scale = 1.0
                        } else if value.magnitude > 1.7 {
                            self.scale = 1.7
                        } else {
                            self.scale = value.magnitude
                        }
                    }
                )
            }
        }
    }
}

@available(iOS 13.0, *)
class ImageLoader: ObservableObject {
    @Published var dataIsValid = false
    var data: Data?

    init(urlString:String) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.dataIsValid = true
                self.data = data
            }
        }
        task.resume()
    }
}

func imageFromData(_ data: Data) -> UIImage {
    UIImage(data: data) ?? UIImage()
}
