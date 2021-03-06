//
//  RendererProtocol.swift
//  MetalDay1
//
//  Created by MikiTakahashi on 2018/11/29.
//  Copyright © 2018 MikiTakahashi. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright (c) 2018 MikiTakahashi
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import Metal
import MetalKit


class Renderer:NSObject {
    // local datas
    private var vertices: [Vertex]!
    private var vertexBuffer: MTLBuffer!
    private var indices: [UInt16]!
    private var indexBuffer: MTLBuffer!
    // for MetalAPI
    private var mtlDevice: MTLDevice!
    private var mtkview: MTKView!
    
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    
    private var uniforms: Uniforms!
    private var preferredFramesTime: Float!
    
    init(metalKitView mtkView: MTKView) {
        super.init()
        self.mtkview = mtkView
        
        guard let device = mtkView.device else {
            print("mtkview doesn't have mtlDevice")
            return
        }
        
        self.mtlDevice = device
        
        commandQueue = device.makeCommandQueue()
        vertices = [Vertex]()
        indices = [UInt16]()
        uniforms = Uniforms(time: Float(0.0), aspectRatio: Float(0.0), touch: float2())
        uniforms.aspectRatio = Float(mtkView.frame.size.width / mtkView.frame.size.height)
        preferredFramesTime = 1.0 / Float(mtkView.preferredFramesPerSecond)

    }
    
    private func buildPipeline() {
        let library = mtlDevice.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexDay1")
        let fragmentFunction = library?.makeFunction(name: "fragmentDay1")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            try pipelineState = mtlDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error: ", error)
        }
    }
    
    private func buildBuffer() {
        vertexBuffer = mtlDevice.makeBuffer(bytes: vertices, length: vertices.count*MemoryLayout<Vertex>.stride, options: [])
        indexBuffer = mtlDevice.makeBuffer(bytes: indices, length: indices.count*MemoryLayout<UInt16>.stride, options: [])
    }
    
}

extension Renderer: MTKViewDelegate{
    
    public func draw(in view: MTKView) {
        uniforms.time += preferredFramesTime
        print(uniforms.time, preferredFramesTime)
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor else {
                print("cannot get drawable or renderPassDescriptor")
                return
        }
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        commandEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
}

extension Renderer {
    public func setVertices(_ vertices: [float3]) {
        self.vertices += vertices.map({ (pos) -> Vertex in
            return Vertex(position: pos)
        })
    }
    public func setIndices(_ indices: [Int]) {
        self.indices += indices.map({ (n) -> UInt16 in
            return UInt16(n)
        })
    }
    
    public func start () {
        buildBuffer()
        buildPipeline()
        mtkview.delegate = self
    }
    public func applyTouch(touch: float2) {
        uniforms.touch = touch
    }
}

struct Vertex {
    var position: float3
}

struct Uniforms {
    var time: Float
    var aspectRatio: Float
    var touch: float2
}
