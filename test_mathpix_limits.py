#!/usr/bin/env python3
import requests
import base64
from PIL import Image, ImageDraw, ImageFont
import io
import time

# Configuration MathPix
APP_ID = "mathsx_8528f9_05358c"
APP_KEY = "f10fb03d7bcd7bfa68d144580cc1268f97f48e61386e687bf68c5044056348c0"
MATHPIX_URL = "https://api.mathpix.com/v3/text"

def create_test_image(size):
    """Crée une image de test avec du texte mathématique"""
    # Créer une image RGB
    img = Image.new('RGB', size, color='white')
    draw = ImageDraw.Draw(img)

    # Essayer de charger une police, sinon utiliser la police par défaut
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 40)
    except:
        font = ImageFont.load_default()

    # Dessiner du texte mathématique
    math_text = "∫ sin(x) dx = -cos(x) + C"
    bbox = draw.textbbox((0, 0), math_text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Centrer le texte
    x = (size[0] - text_width) // 2
    y = (size[1] - text_height) // 2

    draw.text((x, y), math_text, fill='black', font=font)
    return img

def test_image_size(width, height):
    """Teste une taille d'image spécifique"""
    print(f"\n🧪 Test de la taille: {width}x{height}")

    # Créer l'image
    img = create_test_image((width, height))

    # Convertir en JPEG avec compression
    buffer = io.BytesIO()
    img.save(buffer, format='JPEG', quality=85)
    image_data = buffer.getvalue()

    print(f"📊 Taille du fichier: {len(image_data)} bytes ({len(image_data)/1024:.1f} KB)")

    # Encoder en base64
    base64_image = base64.b64encode(image_data).decode('utf-8')

    # Préparer la requête MathPix
    headers = {
        'app_id': APP_ID,
        'app_key': APP_KEY,
        'Content-Type': 'application/json'
    }

    data = {
        'src': f'data:image/jpeg;base64,{base64_image}',
        'formats': ['text', 'latex_styled'],
        'data_options': {
            'include_asciimath': True,
            'include_latex': True
        }
    }

    try:
        print("📤 Envoi à MathPix...")
        start_time = time.time()
        response = requests.post(MATHPIX_URL, json=data, headers=headers, timeout=30)
        end_time = time.time()

        print(f"⏱️  Temps de réponse: {end_time - start_time:.2f}s")
        print(f"📊 Status code: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print("✅ SUCCÈS!")
            print(f"📝 Texte reconnu: {result.get('text', 'N/A')[:50]}...")
            return True, len(image_data)
        else:
            error_msg = response.text
            print(f"❌ ÉCHEC: {error_msg}")
            return False, len(image_data)

    except requests.exceptions.RequestException as e:
        print(f"❌ ERREUR RÉSEAU: {e}")
        return False, len(image_data)
    except Exception as e:
        print(f"❌ ERREUR INATTENDUE: {e}")
        return False, len(image_data)

def find_max_size():
    """Trouve la taille maximale acceptée par MathPix"""
    print("🔍 Recherche de la taille maximale d'image pour MathPix")
    print("=" * 60)

    # Tailles à tester (en pixels)
    test_sizes = [
        (800, 600),    # Petite
        (1200, 900),   # Moyenne
        (1600, 1200),  # Grande
        (2000, 1500),  # Très grande
        (2500, 1875),  # Très très grande
        (3000, 2250),  # Géante
        (3500, 2625),  # Ultra grande
        (4000, 3000),  # Maximale
    ]

    results = []

    for width, height in test_sizes:
        success, file_size = test_image_size(width, height)
        results.append((width, height, success, file_size))

        if not success:
            print(f"\n🚫 ÉCHEC à {width}x{height} ({file_size/1024:.1f} KB)")
            break

        # Attendre un peu entre les requêtes pour ne pas spammer l'API
        time.sleep(1)

    print("\n" + "=" * 60)
    print("📊 RÉSULTATS FINAUX:")

    successful_tests = [r for r in results if r[2]]
    if successful_tests:
        max_success = max(successful_tests, key=lambda x: x[0] * x[1])
        max_width, max_height, _, max_file_size = max_success
        print(f"✅ Taille maximale trouvée: {max_width}x{max_height} ({max_width * max_height:,} pixels)")
        print(f"📁 Taille fichier maximale: {max_file_size/1024:.1f} KB")

        # Calculer les dimensions recommandées (avec marge de sécurité)
        recommended_width = int(max_width * 0.8)
        recommended_height = int(max_height * 0.8)
        print(f"🎯 Dimensions recommandées: {recommended_width}x{recommended_height}")
    else:
        print("❌ Aucune taille n'a fonctionné")

    print("\n📋 Tableau récapitulatif:")
    print("Taille\t\tSuccès\tTaille fichier")
    print("-" * 40)
    for width, height, success, file_size in results:
        status = "✅" if success else "❌"
        print(f"{width}x{height}\t\t{status}\t{file_size/1024:.1f} KB")

if __name__ == "__main__":
    find_max_size()

