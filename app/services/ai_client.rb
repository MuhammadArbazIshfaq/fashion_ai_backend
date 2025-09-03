require 'net/http'
require 'json'
require 'uri'

class AiClient
  AI_URL = ENV.fetch('AI_SERVICE_URL', 'http://localhost:8001') # Python FastAPI service
  ANALYZE_ENDPOINT = ENV.fetch('DEEPFACE_ENDPOINT', '/analyze')

  # Analyze selfie for face detection and emotion recognition
  def self.analyze_selfie_file(file_path_or_io)
    Rails.logger.info "Starting AI analysis for selfie..."
    
    uri = URI.parse("#{AI_URL}#{ANALYZE_ENDPOINT}")
    request = Net::HTTP::Post.new(uri)
    
    # Handle both file paths and uploaded files
    file_to_send = if file_path_or_io.respond_to?(:path)
                     file_path_or_io
                   else
                     File.open(file_path_or_io, 'rb')
                   end

    form = [['file', file_to_send, { filename: 'selfie.jpg', content_type: 'image/jpeg' }]]
    request.set_form(form, 'multipart/form-data')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = 30 # Allow time for AI processing
    
    Rails.logger.info "Sending request to AI service: #{uri}"
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      Rails.logger.info "AI analysis successful: #{result.inspect}"
      
      # Transform the response to standard format
      transform_ai_response(result)
    else
      Rails.logger.error "AI service error: #{response.code} - #{response.body}"
      default_analysis
    end
    
  rescue => e
    Rails.logger.error "AI analyze error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    default_analysis
  ensure
    file_to_send&.close if file_to_send.respond_to?(:close) && file_path_or_io != file_to_send
  end

  # Analyze face features and return style recommendations
  def self.detect_face_features(image_data)
    analysis = analyze_selfie_file(image_data)
    
    {
      face_detected: analysis[:face_detected] || false,
      dominant_emotion: analysis[:dominant_emotion] || 'neutral',
      age_range: analysis[:age_range] || 'young_adult',
      gender: analysis[:gender] || 'unisex',
      style_preferences: derive_style_preferences(analysis),
      color_recommendations: derive_color_recommendations(analysis),
      confidence_score: analysis[:confidence_score] || 0.7
    }
  end

  private

  # Transform AI service response to standard format
  def self.transform_ai_response(response)
    # Check for explicit face detection failure
    face_analysis = response['face_analysis'] || {}
    has_face_error = face_analysis['error'] == 'No face detected'
    
    {
      face_detected: !has_face_error && (response['face_detected'] || response['faces_detected'] || face_analysis.key?('emotion')),
      dominant_emotion: extract_emotion(response),
      age_range: extract_age_range(response),
      gender: extract_gender(response),
      confidence_score: extract_confidence(response),
      raw_analysis: response
    }
  end

  # Extract emotion from various possible response formats
  def self.extract_emotion(response)
    # Return neutral if no face detected
    face_analysis = response['face_analysis'] || {}
    return 'neutral' if face_analysis['error'] == 'No face detected'
    
    face_analysis['emotion'] ||
    response['dominant_emotion'] || 
    response['emotion'] ||
    response.dig('emotions', 0, 'emotion') ||
    response.dig('analysis', 'emotion') ||
    'neutral'
  end

  # Extract age range from response
  def self.extract_age_range(response)
    age = response['age'] || response.dig('analysis', 'age')
    return 'unknown' unless age

    case age.to_i
    when 0..17
      'teen'
    when 18..30
      'young_adult'
    when 31..50
      'middle_aged'
    else
      'mature'
    end
  end

  # Extract gender from response
  def self.extract_gender(response)
    gender = response['gender'] || response.dig('analysis', 'gender')
    return 'unisex' unless gender
    
    gender.downcase == 'man' ? 'male' : (gender.downcase == 'woman' ? 'female' : 'unisex')
  end

  # Extract confidence score
  def self.extract_confidence(response)
    # Return 0 confidence if no face detected
    face_analysis = response['face_analysis'] || {}
    return 0.0 if face_analysis['error'] == 'No face detected'
    
    face_analysis['detection_confidence'] ||
    response['confidence'] || 
    response.dig('analysis', 'confidence') || 
    0.7
  end

  # Derive style preferences based on analysis
  def self.derive_style_preferences(analysis)
    emotion = analysis[:dominant_emotion]&.downcase || 'neutral'
    age_range = analysis[:age_range] || 'young_adult'
    
    base_styles = case emotion
                  when 'happy', 'joy'
                    ['vibrant', 'casual', 'trendy']
                  when 'neutral', 'calm'
                    ['minimal', 'classic', 'professional']
                  when 'sad', 'melancholy'
                    ['cozy', 'comfortable', 'muted']
                  when 'angry', 'intense'
                    ['edgy', 'bold', 'statement']
                  else
                    ['versatile', 'casual']
                  end

    # Adjust based on age
    case age_range
    when 'teen'
      base_styles += ['trendy', 'streetwear', 'casual']
    when 'young_adult'
      base_styles += ['modern', 'versatile']
    when 'middle_aged', 'mature'
      base_styles += ['sophisticated', 'classic', 'professional']
    end

    base_styles.uniq
  end

  # Derive color recommendations based on analysis
  def self.derive_color_recommendations(analysis)
    emotion = analysis[:dominant_emotion]&.downcase || 'neutral'
    
    case emotion
    when 'happy', 'joy'
      ['bright', 'yellow', 'orange', 'pink', 'light_blue']
    when 'neutral', 'calm'
      ['white', 'beige', 'navy', 'gray', 'black']
    when 'sad', 'melancholy'
      ['muted', 'gray', 'brown', 'dark_blue', 'forest_green']
    when 'angry', 'intense'
      ['black', 'red', 'dark', 'burgundy', 'charcoal']
    else
      ['versatile', 'white', 'black', 'navy', 'beige']
    end
  end

  # Default analysis when AI service fails
  def self.default_analysis
    {
      face_detected: true,
      dominant_emotion: 'neutral',
      age_range: 'young_adult',
      gender: 'unisex',
      confidence_score: 0.5,
      raw_analysis: { error: 'AI service unavailable' }
    }
  end
end
