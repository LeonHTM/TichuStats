//
//  TichuRulesPDFView.swift
//  TichuStats
//
//  Created by Leon on 22.06.2026.
//


import SwiftUI
import PDFKit

struct TichuRulesPDFView: View {
    var body: some View {
        PDFKitView()
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(String(localized:"gamesettings.section.howToPlay.officialRules.title"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PDFKitView: UIViewRepresentable {
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        pdfView.displayBox = .cropBox

        if let url = Self.resolvedPDFURL() {
            pdfView.document = PDFDocument(url: url)
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        DispatchQueue.main.async {
            let scale = pdfView.scaleFactorForSizeToFit

            pdfView.scaleFactor = scale
            if UIDevice.current.userInterfaceIdiom == .pad {
                pdfView.minScaleFactor = scale/4
            } else {
                pdfView.minScaleFactor = scale
            }

            pdfView.maxScaleFactor = scale * 5
        }
    }
    
    
    static func resolveGeneralURL(urlDomain: String, urlString: String) -> URL?{
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        let resultingString = urlDomain+"/"+languageCode+urlString
        
        if let url = URL(string: resultingString){
            return url
        }else{
            return nil
        }

    }

    private static func resolvedPDFURL() -> URL? {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"

        let candidateName = "tichu-rules-\(languageCode)"

        if let url = Bundle.main.url(forResource: candidateName, withExtension: "pdf") {
            return url
        }

        return Bundle.main.url(forResource: "tichu-rules-en", withExtension: "pdf")
    }
}
