import re

def process():
    try:
        with open('lib/data/app_state.dart', 'r', encoding='utf-8') as f:
            content = f.read()

        start_idx = content.find('final List<Product> sampleProducts = [')
        end_idx = content.find('];', start_idx) + 2
        
        list_content = content[start_idx:end_idx]
        products = re.split(r'(Product\()', list_content)

        category_counts = {}

        for i in range(2, len(products), 2):
            prod_body = products[i]
            m = re.search(r"category:\s*'([^']+)'", prod_body)
            if m:
                cat = m.group(1)
                if cat not in category_counts:
                    category_counts[cat] = 0
                category_counts[cat] += 1
                
                if category_counts[cat] % 2 == 0:
                    prod_body = re.sub(r'\s*originalPrice:\s*\d+(\.\d+)?,', '', prod_body)
                    products[i] = prod_body

        new_list_content = ''.join(products)
        
        with open('lib/data/app_state.dart', 'w', encoding='utf-8') as f:
            f.write(content[:start_idx] + new_list_content + content[end_idx:])
        print('Success!')
    except Exception as e:
        print(f"Error: {e}")

process()
