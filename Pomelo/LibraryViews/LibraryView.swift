import SwiftUI

struct LibraryView: View {
    @Binding var urlgame: PomeloGame?
    @State var core: Core

    var body: some View {
        BootOSView()
    }
}

func getDeveloperNames() -> String {
    "MeloZu"
}
