import SwiftUI

struct ZoomControls: View {
    @Bindable var settings: DisplaySettings
    var isEnabled: Bool

    private var zoomLabel: String {
        "\(Int(round(settings.zoomLevel * 100)))%"
    }

    var body: some View {
        ControlGroup {
            Button {
                settings.zoomOut()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 10))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
            }
            .disabled(!isEnabled)

            Button {
                settings.zoomReset()
            } label: {
                Text(zoomLabel)
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .frame(minWidth: 40)
                    .padding(.vertical, 4)
            }
            .disabled(!isEnabled)

            Button {
                settings.zoomIn()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
            }
            .disabled(!isEnabled)
        }
        .controlGroupStyle(.navigation)
    }
}
