#!/usr/bin/env python3
import argparse

def generate_ssh_config(input_file, output_file, username, prefix, key_path):
    """
    Генерирует конфигурационный файл SSH из списка IP-адресов и имен серверов
    """
    try:
        with open(input_file, 'r') as f:
            servers = f.readlines()
        
        config_content = []
        for line in servers:
            line = line.strip()
            if not line or line.startswith('#'):
                continue  # Пропускаем пустые строки и комментарии
            
            parts = line.split()
            if len(parts) != 2:
                print(f"Пропускаем некорректную строку: {line}")
                continue
            
            ip, hostname = parts
            config_block = f"""Host {prefix}{hostname}
    HostName {ip}
    User {username}
    IdentityFile {key_path}
"""
            config_content.append(config_block)
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(config_content))
        
        print(f"Конфигурация успешно записана в {output_file}")
    
    except Exception as e:
        print(f"Произошла ошибка: {str(e)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Генератор SSH-конфигурации')
    parser.add_argument('-i', '--input', required=True, help='Входной файл с IP и именами серверов')
    parser.add_argument('-o', '--output', required=True, help='Выходной файл конфигурации SSH')
    parser.add_argument('-u', '--user', required=True, help='Имя пользователя SSH')
    parser.add_argument('-p', '--prefix', required=False, help='Префикс для имени хоста')
    parser.add_argument('-k', '--key-path', required=True, help='Путь к ключу SSH')
    
    args = parser.parse_args()
    
    generate_ssh_config(args.input, args.output, args.user, args.prefix, args.key_path)