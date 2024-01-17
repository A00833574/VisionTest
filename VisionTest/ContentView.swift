import Vision
import SwiftUI

struct ContentView: View {
    @State private var imageTaken : UIImage?
    @State private var nutritionFacts = [String: String]()
    @State private var isLoading = false
    
    func recognizeAndParseText() {
        print("reading text")
        let requestHandler = VNImageRequestHandler(cgImage: self.imageTaken!.cgImage!)
        
        let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            self.parseText(from: observations)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([recognizeTextRequest])
                
                self.isLoading = false
            }
            catch {
                print(error)
            }
        }
    }
    
    func parseText(from observations: [VNRecognizedTextObservation]) {
        var nutritionFacts: [String: String] = [:]
        let keysOfInterest = ["Calories", "Total Fat", "Sodium", "Total Carbohydrate", "Total Sugars", "Protein"]

        for observation in observations {
            if let topCandidate = observation.topCandidates(1).first {
                let text = topCandidate.string
                if let range = text.range(of: " ", options: .backwards) {
                    let key = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let value = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                    if keysOfInterest.contains(key) {
                        nutritionFacts[key] = value
                    }
                }
            }
        }

        DispatchQueue.main.async {
            self.nutritionFacts = nutritionFacts
        }
    }
    
    var pictureTakenView : some View {
        VStack {
            Image(uiImage: self.imageTaken!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            Button(action: {
                self.imageTaken = nil
                self.nutritionFacts = [:]
            }, label: {
                HStack {
                    Image(systemName: "camera")
                    Text("Re-take picture")
                }
            })
            List {
                ForEach(self.nutritionFacts.keys.sorted(), id: \.self) { key in
                    Text("\(key): \(self.nutritionFacts[key]!)")
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            if (self.imageTaken == nil) {
                CameraView(image: self.$imageTaken)
            } else {
                if (!self.isLoading) {
                    self.pictureTakenView
                        .onAppear {
                            self.recognizeAndParseText()
                        }
                }
                else {
                    ProgressView()
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
