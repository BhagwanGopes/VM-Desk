import SwiftUI
import Virtualization
import Metal
import MetalKit

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

    private weak var virtualMachine: VZVirtualMachine?
    private var graphicsDeviceConfig: VZVirtioGraphicsDeviceConfiguration?

    private var displayLink: CVDisplayLink?
    private var framebufferTexture: MTLTexture?

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

        // Simple pass-through shader for framebuffer rendering
        let library = try? device.makeDefaultLibrary(bundle: .main)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
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
              let pipelineState = pipelineState else {
            return
        }

        guard let drawable = metalLayer.nextDrawable() else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        // TODO: Get framebuffer from VZVirtioGraphicsDevice and render as texture
        // For now, just clear to black

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
