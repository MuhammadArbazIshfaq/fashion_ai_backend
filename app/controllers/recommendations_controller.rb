class RecommendationsController < ApplicationController
  before_action :set_user, only: [:create, :index]

  # POST /users/:user_id/recommendations
  def create
    Rails.logger.info "Creating recommendations for user #{@user.id}"
    
    begin
      analysis_result = process_input_data
      Rails.logger.info "Analysis result: #{analysis_result.inspect}"

      if analysis_result[:face_detected] == false
        return render json: { 
          error: 'No face detected in the uploaded image. Please upload a clear selfie with a visible face.',
          details: 'Make sure your face is well-lit, centered in the image, and clearly visible.',
          recommendations: []
        }, status: :unprocessable_content
      end

      # Generate recommendations based on AI analysis
      recommendations = Recommender.for(user: @user, analysis: analysis_result)
      Rails.logger.info "Generated #{recommendations.size} recommendations"

      # Create recommendation records
      created_recommendations = recommendations.map do |rec|
        Recommendation.create!(
          user: @user,
          product: rec[:product],
          score: rec[:score],
          reason: rec[:reason] || "AI-based recommendation",
          selfie_url: analysis_result[:selfie_url],
          analysis_json: analysis_result.except(:selfie_url)
        )
      end

      render json: {
        message: "Successfully generated #{created_recommendations.size} recommendations",
        analysis_summary: {
          face_detected: analysis_result[:face_detected],
          dominant_emotion: analysis_result[:dominant_emotion],
          confidence_score: analysis_result[:confidence_score]
        },
        recommendations: created_recommendations.as_json(include: {
          product: {
            only: [:id, :name, :category, :size, :color, :price, :image_url, :tags]
          }
        })
      }, status: :created

    rescue StandardError => e
      Rails.logger.error "Error creating recommendations: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: { 
        error: 'Failed to generate recommendations. Please try again.',
        details: e.message
      }, status: :internal_server_error
    end
  end

  # GET /users/:user_id/recommendations
  def index
    recommendations = @user.recommendations
                           .includes(:product)
                           .order(created_at: :desc)
                           .limit(20)

    render json: {
      user_id: @user.id,
      total_recommendations: recommendations.size,
      recommendations: recommendations.as_json(include: {
        product: {
          only: [:id, :name, :category, :size, :color, :price, :image_url, :tags]
        }
      })
    }
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  # Process either selfie upload or pre-analyzed data
  def process_input_data
    # Accept 'selfie', 'image', or 'file' parameter names for flexibility
    image_param = params[:selfie] || params[:image] || params[:file]
    
    if image_param.present?
      # Process uploaded selfie/image
      process_selfie_upload(image_param)
    elsif params[:analysis].present?
      # Use provided analysis data
      process_provided_analysis
    else
      # No input data provided
      Rails.logger.error "No selfie/image or analysis data provided"
      {
        face_detected: false,
        dominant_emotion: 'neutral',
        confidence_score: 0.0,
        error: 'No input data provided'
      }
    end
  end

  # Process uploaded selfie image
  def process_selfie_upload(image_param = nil)
    Rails.logger.info "Processing selfie upload..."
    
    selfie = image_param || params[:selfie] || params[:image] || params[:file]
    
    # Validate file type
    unless valid_image_file?(selfie)
      Rails.logger.error "Invalid image file type"
      return {
        face_detected: false,
        error: 'Invalid image file type. Please upload JPEG, PNG, or GIF.'
      }
    end

    # Create temporary file for AI analysis
    temp_file = create_temp_file(selfie)
    
    begin
      # Call AI service for face detection and analysis
      ai_analysis = AiClient.detect_face_features(temp_file.path)
      Rails.logger.info "AI analysis completed: #{ai_analysis.inspect}"
      
      # Store selfie URL for reference (optional)
      selfie_url = store_selfie(selfie) if ai_analysis[:face_detected]
      
      ai_analysis.merge(
        selfie_url: selfie_url,
        processing_time: Time.current
      )
      
    ensure
      temp_file&.close
      temp_file&.unlink if temp_file
    end
  end

  # Process provided analysis JSON
  def process_provided_analysis
    Rails.logger.info "Processing provided analysis..."
    
    begin
      analysis = JSON.parse(params[:analysis])
      
      {
        face_detected: analysis['face_detected'] || true,
        dominant_emotion: analysis['dominant_emotion'] || analysis['emotion'] || 'neutral',
        age_range: analysis['age_range'] || 'young_adult',
        gender: analysis['gender'] || 'unisex',
        style_preferences: analysis['style_preferences'] || [],
        color_recommendations: analysis['color_recommendations'] || [],
        confidence_score: analysis['confidence_score'] || 0.8,
        source: 'provided_analysis'
      }
      
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse provided analysis: #{e.message}"
      {
        face_detected: false,
        error: 'Invalid analysis data format'
      }
    end
  end

  # Validate uploaded image file
  def valid_image_file?(file)
    return false unless file.respond_to?(:content_type)
    
    allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']
    allowed_types.include?(file.content_type.to_s.downcase)
  end

  # Create temporary file for AI processing
  def create_temp_file(uploaded_file)
    temp_file = Tempfile.new(['selfie', '.jpg'])
    temp_file.binmode
    
    if uploaded_file.respond_to?(:read)
      temp_file.write(uploaded_file.read)
    else
      temp_file.write(File.read(uploaded_file.path))
    end
    
    temp_file.rewind
    temp_file
  end

  # Store selfie for future reference (optional)
  def store_selfie(selfie)
    # This is optional - you can implement ActiveStorage or file storage here
    # For now, we'll just return a placeholder
    "stored_selfie_#{@user.id}_#{Time.current.to_i}.jpg"
  end
end
