# Example Python AI Service for Face Detection
# This is a reference implementation - you can customize based on your needs
# Run this with: uvicorn ai_service_example:app --host 0.0.0.0 --port 8001

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
from deepface import DeepFace
import tempfile
import os
from typing import Dict, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Fashion AI Face Detection Service", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "Fashion AI Face Detection Service is running", "status": "healthy"}

@app.post("/analyze")
async def analyze_face(file: UploadFile = File(...)) -> Dict[str, Any]:
    """
    Analyze uploaded image for face detection and emotion recognition
    """
    try:
        logger.info(f"Analyzing uploaded file: {file.filename}")
        
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Read image data
        image_data = await file.read()
        
        # Convert to OpenCV format
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Could not decode image")
        
        # Save to temporary file for DeepFace processing
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            cv2.imwrite(temp_file.name, image)
            temp_path = temp_file.name
        
        try:
            # Analyze with DeepFace
            analysis = DeepFace.analyze(
                img_path=temp_path,
                actions=['age', 'gender', 'race', 'emotion'],
                enforce_detection=False
            )
            
            # Handle both single face and multiple faces
            if isinstance(analysis, list):
                analysis = analysis[0] if analysis else {}
            
            # Extract emotion information
            emotions = analysis.get('emotion', {})
            dominant_emotion = analysis.get('dominant_emotion', 'neutral')
            
            # Extract other features
            age = analysis.get('age', 25)
            gender = analysis.get('dominant_gender', 'Man')
            
            # Determine face detection success
            face_detected = len(analysis) > 0 and 'emotion' in analysis
            
            result = {
                "face_detected": face_detected,
                "dominant_emotion": dominant_emotion.lower(),
                "emotions": emotions,
                "age": int(age),
                "gender": gender.lower(),
                "confidence_score": calculate_confidence(emotions),
                "analysis": analysis
            }
            
            logger.info(f"Analysis completed successfully: {result}")
            return result
            
        finally:
            # Clean up temporary file
            if os.path.exists(temp_path):
                os.unlink(temp_path)
                
    except Exception as e:
        logger.error(f"Error analyzing image: {str(e)}")
        return {
            "face_detected": False,
            "dominant_emotion": "neutral",
            "error": str(e),
            "confidence_score": 0.0
        }

def calculate_confidence(emotions: Dict[str, float]) -> float:
    """
    Calculate confidence score based on emotion detection
    """
    if not emotions:
        return 0.0
    
    # Get the highest emotion score as confidence
    max_confidence = max(emotions.values()) / 100.0 if emotions else 0.0
    return min(max_confidence, 1.0)

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "service": "Fashion AI Face Detection",
        "version": "1.0.0",
        "dependencies": {
            "opencv": "installed",
            "deepface": "installed",
            "fastapi": "installed"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
