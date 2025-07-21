import os
import argparse
from pathlib import Path

class DirectoryTree:
    def __init__(self, ignore_patterns=None):
        """
        初始化目录树生成器
        :param ignore_patterns: 要忽略的文件/文件夹模式列表
        """
        self.ignore_patterns = ignore_patterns or [
            '.git', '.gitignore', '__pycache__', '.vscode', 
            '.idea', '*.pyc', '*.pyo', '*.pyd', '.DS_Store',
            'node_modules', '.env', '*.log'
        ]
    
    def should_ignore(self, path):
        """检查是否应该忽略某个路径"""
        name = os.path.basename(path)
        for pattern in self.ignore_patterns:
            if pattern.startswith('*') and name.endswith(pattern[1:]):
                return True
            elif pattern == name:
                return True
        return False
    
    def generate_tree(self, root_path, max_depth=None, current_depth=0):
        """
        生成目录树结构
        :param root_path: 根目录路径
        :param max_depth: 最大深度限制
        :param current_depth: 当前深度
        :return: 树状结构字符串
        """
        if max_depth is not None and current_depth > max_depth:
            return ""
        
        root = Path(root_path)
        if not root.exists():
            return f"错误: 路径 '{root_path}' 不存在"
        
        tree_str = ""
        if current_depth == 0:
            tree_str += f"{root.name}/\n"
        
        try:
            items = sorted(root.iterdir(), key=lambda x: (x.is_file(), x.name.lower()))
            items = [item for item in items if not self.should_ignore(item)]
            
            for i, item in enumerate(items):
                is_last = i == len(items) - 1
                prefix = "└── " if is_last else "├── "
                
                if item.is_dir():
                    tree_str += "│   " * current_depth + prefix + f"{item.name}/\n"
                    if max_depth is None or current_depth < max_depth:
                        subtree = self.generate_tree(item, max_depth, current_depth + 1)
                        if subtree:
                            # 调整子树的缩进
                            subtree_lines = subtree.split('\n')[1:]  # 跳过根目录行
                            for line in subtree_lines:
                                if line.strip():
                                    if is_last:
                                        tree_str += "    " * (current_depth + 1) + line[4:] + "\n"
                                    else:
                                        tree_str += "│   " * (current_depth + 1) + line[4:] + "\n"
                else:
                    file_size = self.get_file_size(item)
                    tree_str += "│   " * current_depth + prefix + f"{item.name} ({file_size})\n"
                    
        except PermissionError:
            tree_str += "│   " * current_depth + "└── [权限拒绝]\n"
            
        return tree_str
    
    def get_file_size(self, file_path):
        """获取文件大小的友好显示格式"""
        try:
            size = file_path.stat().st_size
            for unit in ['B', 'KB', 'MB', 'GB']:
                if size < 1024.0:
                    return f"{size:.1f}{unit}"
                size /= 1024.0
            return f"{size:.1f}TB"
        except:
            return "未知大小"
    
    def generate_file_list(self, root_path, max_depth=None):
        """
        生成简单的文件路径列表
        :param root_path: 根目录路径
        :param max_depth: 最大深度限制
        :return: 文件路径列表
        """
        file_list = []
        
        def scan_directory(path, current_depth=0):
            if max_depth is not None and current_depth > max_depth:
                return
            
            try:
                for item in sorted(Path(path).iterdir(), key=lambda x: x.name.lower()):
                    if self.should_ignore(item):
                        continue
                    
                    relative_path = item.relative_to(Path(root_path))
                    
                    if item.is_dir():
                        file_list.append(f"📁 {relative_path}/")
                        scan_directory(item, current_depth + 1)
                    else:
                        file_size = self.get_file_size(item)
                        file_list.append(f"📄 {relative_path} ({file_size})")
            except PermissionError:
                file_list.append(f"❌ {Path(path).relative_to(Path(root_path))}/ [权限拒绝]")
        
        scan_directory(root_path)
        return file_list
    
    def save_to_file(self, content, output_file):
        """保存内容到文件"""
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ 结果已保存到: {output_file}")
        except Exception as e:
            print(f"❌ 保存文件失败: {e}")

def main():
    parser = argparse.ArgumentParser(description='生成目录树结构')
    parser.add_argument('path', nargs='?', default=r'e:\NEC', help='要扫描的目录路径 (默认: 当前目录)')
    parser.add_argument('-d', '--depth', type=int, help='最大扫描深度')
    parser.add_argument('-o', '--output', help='输出文件路径')
    parser.add_argument('-f', '--format', choices=['tree', 'list'], default='tree', 
                       help='输出格式: tree(树状) 或 list(列表)')
    parser.add_argument('--ignore', nargs='*', help='额外要忽略的文件/文件夹模式')
    
    args = parser.parse_args()
    
    # 创建目录树生成器
    ignore_patterns = None
    if args.ignore:
        default_ignore = [
            '.git', '.gitignore', '__pycache__', '.vscode', 
            '.idea', '*.pyc', '*.pyo', '*.pyd', '.DS_Store',
            'node_modules', '.env', '*.log'
        ]
        ignore_patterns = default_ignore + args.ignore
    
    tree_generator = DirectoryTree(ignore_patterns)
    
    print(f"📂 扫描目录: {os.path.abspath(args.path)}")
    if args.depth:
        print(f"📏 最大深度: {args.depth}")
    print(f"📋 输出格式: {args.format}")
    print("-" * 50)
    
    # 生成内容
    if args.format == 'tree':
        content = tree_generator.generate_tree(args.path, args.depth)
    else:
        file_list = tree_generator.generate_file_list(args.path, args.depth)
        content = "\n".join(file_list)
    
    # 输出结果
    print(content)
    
    # 保存到文件
    if args.output:
        tree_generator.save_to_file(content, args.output)

if __name__ == "__main__":
    main()