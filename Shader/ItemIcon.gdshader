shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.6, 0.1, 1.0);

uniform float outline_size = 1.0;
uniform float glow_size = 4.0;
uniform float glow_strength = 0.7;

uniform bool rarity_effect = true;


void fragment() {

	vec4 tex = texture(TEXTURE, UV);

	// =====================================================
	// ITEM GỐC
	// =====================================================

	if (tex.a > 0.01) {

		COLOR = tex;

	}
	else if (!rarity_effect) {

		// COMMON → không viền, không glow

		COLOR = vec4(0.0);

	}
	else {

		vec2 pixel = TEXTURE_PIXEL_SIZE;

		float nearest_alpha = 0.0;
		float glow_alpha = 0.0;


		// =================================================
		// TÌM ALPHA XUNG QUANH ITEM
		// =================================================

		for (float x = -4.0; x <= 4.0; x += 1.0) {

			for (float y = -4.0; y <= 4.0; y += 1.0) {

				if (x == 0.0 && y == 0.0) {
					continue;
				}


				float distance_to_pixel = length(vec2(x, y));


				if (distance_to_pixel > glow_size) {
					continue;
				}


				float sample_alpha = texture(
					TEXTURE,
					UV + vec2(x, y) * pixel
				).a;


				// =============================================
				// VIỀN
				// =============================================

				if (distance_to_pixel <= outline_size) {

					nearest_alpha = max(
						nearest_alpha,
						sample_alpha
					);

				}


				// =============================================
				// GLOW
				// =============================================

				float fade = 1.0 - (
					distance_to_pixel / glow_size
				);


				glow_alpha = max(
					glow_alpha,
					sample_alpha * fade
				);
			}
		}


		// =================================================
		// VIỀN
		// =================================================

		if (nearest_alpha > 0.01) {

			COLOR = vec4(
				outline_color.rgb,
				1.0
			);

		}


		// =================================================
		// GLOW
		// =================================================

		else if (glow_alpha > 0.01) {

			COLOR = vec4(
				outline_color.rgb,
				glow_alpha * glow_strength
			);

		}


		else {

			COLOR = vec4(0.0);

		}
	}
}