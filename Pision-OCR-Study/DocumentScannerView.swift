//
//  DocumentScannerView.swift
//  VisionKitStudy1
//
//  Created by 여성일 on 6/25/25.
//
import SwiftUI
import Vision
import VisionKit

/*
 VisionKit은 UIKit 기반 프레임워크이기 때문에, UIViewControllerRepresentable로 UIKit 매핑 해야함
 UIViewControllerRepresentable를 채택하면, updateUIViewController, makeUIViewController 메소드를 구현해주어야함. makeCoordinator는 옵셔널
 */
struct DocumentScannerView: UIViewControllerRepresentable {
  @Binding var scannedText: String
  @Environment(\.presentationMode) var presentationMode
  
  /*
   Coordinator를 만드는 메소드
   Coordinator는 UIView -> SwiftUI로 연결하는 브릿지 역할
   */
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  // UIKit ViewController 만드는 메소드
  func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
    let scannerVC = VNDocumentCameraViewController() // 원래는 따로 뷰컨트롤러를 만들어야하지만, visionKit에서 제공하는 UI사용하면 됨.
    scannerVC.delegate = context.coordinator
    return scannerVC
  }
  
  // SwiftUI의 상태가 바뀌면 뷰컨트롤러를 최신 상태로 업데이트하기 위한 메소드
  func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
  
  // VNDocumentCameraViewControllerDelegate : 스캔 델리게이트 프로토콜
  class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    var parent: DocumentScannerView // 부모뷰
    
    init(_ parent: DocumentScannerView) {
      self.parent = parent
    }
    
    // 스캔을 완료 했을 때 호출되는 메소드 -> save 버튼 누르면 호출 되는 메소드
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
      guard scan.pageCount > 0 else {
        parent.scannedText = "스캔된 페이지가 없습니다."
        return
      }
      
      let image = scan.imageOfPage(at: 0) // 스캔 이미지 중 첫번째 이미지 선택
      performOCR(on: image)
      
      // ViewController 닫기
      controller.dismiss(animated: true)
    }
    
    // 스캔을 취소 했을 때 호출되는 메소드
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
      controller.dismiss(animated: true) // ViewController 닫기
    }
    
    // 스캔 도중 에러가 발생했을 때 호출되는 메소드
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: any Error) {
      controller.dismiss(animated: true) // ViewController 닫기
      parent.scannedText = "Scan Error : \(error.localizedDescription)"
    }
    
    // OCR 처리 커스텀 메소드
    private func performOCR(on image: UIImage) {
      guard let cgImage = image.cgImage else {
        parent.scannedText = "⚠️ 이미지 처리에 문제가 발생했어요."
        return
      }
      
      // 이미지 분석 객체 클래스 / 옵션 : 추가적인 정보나 힌트를 제공하는 딕셔너리 .. 보통은 [:]
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      
      // 이미지의 추가적인 정보 제공을 위한 request 변수
      let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return } // 추출 결과 값
        
        // 에러가 있다면 에러처리
        if let error = error {
          self.parent.scannedText = "⚠️ 텍스트 인식에 실패했어요. \(error.localizedDescription)"
          return
        }
        
        let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
        /*
         추출 결과 값에서 compactMap으로 nil을 제외한 새 배열을 반환 -> 인식 결과 값이 여러 개인데,
         그 중 정확도가 제일 높은 것 1개만 선택해서 반환
         */
        
        print("추출 된 텍스트 : \(recognizedStrings)")
        
        DispatchQueue.main.async {
          self.parent.scannedText = recognizedStrings.joined(separator: "\n")
          /*
           추출 된 텍스트를 줄바꿈(\n)해서 반환
           ex) ["일", "다니엘리", "내일", "런도", "파덕", "루카"]
           일
           다니엘리
           내일
           런도
           파덕
           루카
           */
        }
      }
      
      // iOS 16 이상만 revision3 지원
      if #available(iOS 16.0, *) {
        let revision3 = VNRecognizeTextRequestRevision3 // 인식 엔진 -> revision3
        request.revision = revision3
        request.recognitionLevel = .accurate // 인식 정확도 (accurate = 더 정확함, 더 많은 시간이 소요, fast = 상대적으로 덜 정확함, 더 빠름)
        request.recognitionLanguages = ["ko-KR"] // 한국어
        request.usesLanguageCorrection = true // 언어 교정기능
      } else {
        let revision2 = VNRecognizeTextRequestRevision2
        request.revision = revision2
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR"]
        request.usesLanguageCorrection = true
      }
      
      try? handler.perform([request])
    }
  }
}
