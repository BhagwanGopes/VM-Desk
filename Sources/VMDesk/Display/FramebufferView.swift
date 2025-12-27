import SwiftUI
import Virtualization
import Metal
import MetalKit
import simd

/// SwiftUI wrapper for VM display view
struct VMDisplayView: NSViewRepresentable {
    let virtualMachine: VZVirtualMachine
    let graphicsDevice: VZVirtioGraphicsDeviceConfiguration

    func makeNSView(context: Context) -> VMDisplayNSView {
        let view = VMDisplayNSView()
        view.configure(with: virtualMachine, graphicsDevice: graphicsDevice)
        return view
    }

    func updateNSView(_ nsView: VMDisplayNSView, context: Context) {
        // Updates handled by view internally
    }
}

/// NSView subclass with Metal rendering for VM framebuffer
final class VMDisplayNSView: NSView {
    private var metalLayer: CAMetalLayer?
    private var metalDevice: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var samplerState: MTLSamplerState?

    private weak var virtualMachine: VZVirtualMachine?
    private var graphicsDeviceConfig: VZVirtioGraphicsDeviceConfiguration?

    private var displayLink: CVDisplayLink?
    private var framebufferTexture: MTLTexture?

    // Vertex buffers for fullscreen quad
    private var vertexBuffer: MTLBuffer?
    private var texCoordBuffer: MTLBuffer?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupMetal()
        wantsLayer = true
        layer = metalLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    deinit {
        stopDisplayLink()
    }

    // MARK: - Configuration

    func configure(with vm: VZVirtualMachine, graphicsDevice: VZVirtioGraphicsDeviceConfiguration) {
        self.virtualMachine = vm
        self.graphicsDeviceConfig = graphicsDevice

        // Set initial resolution from graphics device
        if let scanout = graphicsDevice.scanouts.first {
            let size = NSSize(
                width: CGFloat(scanout.widthInPixels),
                height: CGFloat(scanout.heightInPixels)
            )
            updateFramebufferSize(size)
        }

        startDisplayLink()
    }

    // MARK: - Metal Setup

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal not supported on this device")
            return
        }

        metalDevice = device
        commandQueue = device.makeCommandQueue()

        // Create Metal layer
        let layer = CAMetalLayer()
        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.framebufferOnly = false
        layer.contentsScale = window?.backingScaleFactor ?? 2.0
        metalLayer = layer

        setupRenderPipeline()
    }

    private func setupRenderPipeline() {
        guard let device = metalDevice else { return }

        // Load shader library
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create Metal library")
            return
        }

        // Create render pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        // Create sampler state for texture sampling
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)

        // Create vertex buffers for fullscreen quad
        setupVertexBuffers()
    }

    private func setupVertexBuffers() {
        guard let device = metalDevice else { return }

        // Fullscreen quad vertices in NDC coordinates
        let vertices: [SIMD2<Float>] = [
            SIMD2(-1.0, -1.0),  // Bottom-left
            SIMD2( 1.0, -1.0),  // Bottom-right
            SIMD2(-1.0,  1.0),  // Top-left
            SIMD2( 1.0, -1.0),  // Bottom-right
            SIMD2( 1.0,  1.0),  // Top-right
            SIMD2(-1.0,  1.0)   // Top-left
        ]

        // Texture coordinates
        let texCoords: [SIMD2<Float>] = [
            SIMD2(0.0, 1.0),  // Bottom-left
            SIMD2(1.0, 1.0),  // Bottom-right
            SIMD2(0.0, 0.0),  // Top-left
            SIMD2(1.0, 1.0),  // Bottom-right
            SIMD2(1.0, 0.0),  // Top-right
            SIMD2(0.0, 0.0)   // Top-left
        ]

        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SIMD2<Float>>.stride * vertices.count,
            options: .storageModeShared
        )

        texCoordBuffer = device.makeBuffer(
            bytes: texCoords,
            length: MemoryLayout<SIMD2<Float>>.stride * texCoords.count,
            options: .storageModeShared
        )
    }

    // MARK: - Display Link

    private func startDisplayLink() {
        var displayLink: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)

        if let displayLink = displayLink {
            CVDisplayLinkSetOutputCallback(displayLink, { _, _, _, _, _, userData in
                guard let view = userData?.assumingMemoryBound(to: VMDisplayNSView.self).pointee else {
                    return kCVReturnSuccess
                }

                DispatchQueue.main.async {
                    view.renderFrame()
                }

                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())

            CVDisplayLinkStart(displayLink)
            self.displayLink = displayLink
        }
    }

    private func stopDisplayLink() {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        displayLink = nil
    }

    // MARK: - Rendering

    private func renderFrame() {
        guard let metalLayer = metalLayer,
              let commandQueue = commandQueue,
              let pipelineState = pipelineState,
              let vertexBuffer = vertexBuffer,
              let texCoordBuffer = texCoordBuffer else {
            return
        }

        guard let drawable = metalLayer.nextDrawable() else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)

        // If we have a framebuffer texture, render it
        if let framebuffer = framebufferTexture, let sampler = samplerState {
            renderEncoder.setFragmentTexture(framebuffer, index: 0)
            renderEncoder.setFragmentSamplerState(sampler, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }

        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func updateFramebufferSize(_ size: NSSize) {
        metalLayer?.drawableSize = CGSize(
            width: size.width * (window?.backingScaleFactor ?? 2.0),
            height: size.height * (window?.backingScaleFactor ?? 2.0)
        )
    }

    // MARK: - Input Handling

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        InputHandler.shared.handleKeyEvent(event, for: virtualMachine)
    }

    override func keyUp(with event: NSEvent) {
        InputHandler.shared.handleKeyEvent(event, for: virtualMachine)
    }

    override func mouseDown(with event: NSEvent) {
        InputHandler.shared.handleMouseEvent(event, for: virtualMachine)
    }

    override func mouseMoved(with event: NSEvent) {
        InputHandler.shared.handleMouseEvent(event, for: virtualMachine)
    }

    override func mouseDragged(with event: NSEvent) {
        InputHandler.shared.handleMouseEvent(event, for: virtualMachine)
    }

    override func scrollWheel(with event: NSEvent) {
        InputHandler.shared.handleScrollEvent(event, for: virtualMachine)
    }
}
