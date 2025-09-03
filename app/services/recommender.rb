class Recommender
  # Enhanced emotion to style mapping
  EMOTION_TO_STYLES = {
    "happy" => %w[vibrant bright casual trendy colorful],
    "joy" => %w[vibrant bright casual trendy colorful],
    "neutral" => %w[minimal classic professional versatile],
    "calm" => %w[minimal classic professional versatile],
    "sad" => %w[cozy muted comfortable soft],
    "melancholy" => %w[cozy muted comfortable soft],
    "angry" => %w[edgy dark bold statement],
    "intense" => %w[edgy dark bold statement]
  }.freeze

  # Age-based style preferences
  AGE_TO_STYLES = {
    "teen" => %w[trendy streetwear casual youthful],
    "young_adult" => %w[modern versatile contemporary],
    "middle_aged" => %w[sophisticated classic professional],
    "mature" => %w[elegant timeless refined]
  }.freeze

  # Gender-based style adjustments
  GENDER_TO_STYLES = {
    "male" => %w[masculine structured],
    "female" => %w[feminine flowing],
    "unisex" => %w[versatile neutral]
  }.freeze

  def self.for(user:, analysis:)
    Rails.logger.info "Generating recommendations with analysis: #{analysis.inspect}"
    
    # Extract features from AI analysis
    features = extract_features(analysis)
    Rails.logger.info "Extracted features: #{features.inspect}"
    
    # Get all products and score them
    products = Product.all.to_a
    scored = products.map do |product|
      score = calculate_product_score(product, features)
      {
        product: product,
        score: score[:total_score],
        reason: score[:reasoning],
        confidence: features[:confidence_score] || 0.7
      }
    end

    # Sort by score and return top recommendations
    top_recommendations = scored
                          .select { |s| s[:score] > 0 }
                          .sort_by { |s| -s[:score] }
                          
    # If no scored matches, return random selection
    if top_recommendations.empty?
      Rails.logger.warn "No scored matches found, returning random selection"
      top_recommendations = scored.sample(8).map do |s|
        s[:score] = 0.5
        s[:reason] = "General recommendation based on available inventory"
        s
      end
    end

    top_recommendations.first(8)
  end

  private

  # Extract features from AI analysis
  def self.extract_features(analysis)
    return default_features if analysis.blank?

    # Handle both hash and JSON string
    parsed_analysis = analysis.is_a?(String) ? JSON.parse(analysis) : analysis
    
    {
      emotion: extract_emotion(parsed_analysis),
      age_range: parsed_analysis['age_range'] || parsed_analysis[:age_range] || 'young_adult',
      gender: parsed_analysis['gender'] || parsed_analysis[:gender] || 'unisex',
      style_preferences: parsed_analysis['style_preferences'] || parsed_analysis[:style_preferences] || [],
      color_recommendations: parsed_analysis['color_recommendations'] || parsed_analysis[:color_recommendations] || [],
      confidence_score: parsed_analysis['confidence_score'] || parsed_analysis[:confidence_score] || 0.7,
      face_detected: parsed_analysis['face_detected'] || parsed_analysis[:face_detected] || false
    }
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse analysis JSON: #{e.message}"
    default_features
  end

  # Extract emotion with fallback logic
  def self.extract_emotion(analysis)
    emotion = analysis['dominant_emotion'] || 
              analysis[:dominant_emotion] ||
              analysis['emotion'] || 
              analysis[:emotion] ||
              'neutral'
    
    emotion.to_s.downcase
  end

  # Calculate product compatibility score
  def self.calculate_product_score(product, features)
    total_score = 0.0
    reasoning_parts = []

    # Get product tags as array
    product_tags = product.tags.to_s.split(',').map(&:strip).map(&:downcase)
    
    # 1. Emotion-based scoring (40% weight)
    emotion_styles = EMOTION_TO_STYLES[features[:emotion]] || []
    emotion_matches = (product_tags & emotion_styles).size
    emotion_score = emotion_matches.to_f / [emotion_styles.size, 1].max * 4.0
    total_score += emotion_score
    
    if emotion_matches > 0
      reasoning_parts << "emotion match (#{features[:emotion]}): #{(product_tags & emotion_styles).join(', ')}"
    end

    # 2. Age-based scoring (20% weight)
    age_styles = AGE_TO_STYLES[features[:age_range]] || []
    age_matches = (product_tags & age_styles).size
    age_score = age_matches.to_f / [age_styles.size, 1].max * 2.0
    total_score += age_score
    
    if age_matches > 0
      reasoning_parts << "age-appropriate (#{features[:age_range]}): #{(product_tags & age_styles).join(', ')}"
    end

    # 3. Gender-based scoring (15% weight)
    gender_styles = GENDER_TO_STYLES[features[:gender]] || []
    gender_matches = (product_tags & gender_styles).size
    gender_score = gender_matches.to_f / [gender_styles.size, 1].max * 1.5
    total_score += gender_score

    # 4. Style preferences scoring (15% weight)
    if features[:style_preferences].present?
      style_prefs = features[:style_preferences].map(&:downcase)
      style_matches = (product_tags & style_prefs).size
      style_score = style_matches.to_f / [style_prefs.size, 1].max * 1.5
      total_score += style_score
      
      if style_matches > 0
        reasoning_parts << "style preference: #{(product_tags & style_prefs).join(', ')}"
      end
    end

    # 5. Color-based scoring (10% weight)
    if features[:color_recommendations].present?
      color_recs = features[:color_recommendations].map(&:downcase)
      color_in_tags = product_tags.any? { |tag| color_recs.include?(tag) }
      color_in_name = color_recs.any? { |color| product.name.downcase.include?(color) }
      color_in_color_field = color_recs.include?(product.color.to_s.downcase)
      
      if color_in_tags || color_in_name || color_in_color_field
        total_score += 1.0
        reasoning_parts << "color match"
      end
    end

    # Apply confidence multiplier
    confidence_multiplier = features[:confidence_score] || 0.7
    total_score *= confidence_multiplier

    # Bonus for face detection success
    if features[:face_detected]
      total_score *= 1.1
      reasoning_parts << "AI face detection successful"
    end

    # Generate human-readable reasoning
    reasoning = if reasoning_parts.any?
                  "Recommended based on: #{reasoning_parts.join('; ')}"
                else
                  "General recommendation (score: #{total_score.round(2)})"
                end

    {
      total_score: total_score.round(3),
      reasoning: reasoning
    }
  end

  # Default features when no analysis is available
  def self.default_features
    {
      emotion: 'neutral',
      age_range: 'young_adult',
      gender: 'unisex',
      style_preferences: ['versatile', 'casual'],
      color_recommendations: ['versatile'],
      confidence_score: 0.5,
      face_detected: false
    }
  end
end
