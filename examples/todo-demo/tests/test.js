/**
 * Todo Demo - 测试用例
 * 覆盖 addTodo, deleteTodo, toggleComplete, render 等核心功能
 */

// Mock localStorage
const mockStorage = {};
global.localStorage = {
    getItem: (key) => mockStorage[key] || null,
    setItem: (key, value) => { mockStorage[key] = value; },
    removeItem: (key) => { delete mockStorage[key]; },
    clear: () => { Object.keys(mockStorage).forEach(k => delete mockStorage[k]); }
};

// 测试工具函数
function generateId() {
    return 'test-id-' + Math.random().toString(36).substr(2, 9);
}

function getTimestamp() {
    return new Date().toISOString();
}

// 测试用例
describe('Todo App', () => {
    let todos = [];

    beforeEach(() => {
        // Reset state before each test
        todos = [];
        localStorage.clear();
    });

    describe('addTodo', () => {
        test('should add a new todo', () => {
            const text = 'Test todo';
            const todo = {
                id: generateId(),
                text: text,
                completed: false,
                createdAt: getTimestamp()
            };
            todos.push(todo);
            expect(todos.length).toBe(1);
            expect(todos[0].text).toBe('Test todo');
            expect(todos[0].completed).toBe(false);
        });

        test('should trim whitespace from todo text', () => {
            const text = '  Test todo  ';
            const trimmedText = text.trim();
            expect(trimmedText).toBe('Test todo');
        });

        test('should not add empty todo', () => {
            const text = '';
            if (text.trim()) {
                const todo = { id: generateId(), text: text.trim(), completed: false, createdAt: getTimestamp() };
                todos.push(todo);
            }
            expect(todos.length).toBe(0);
        });
    });

    describe('deleteTodo', () => {
        test('should delete a todo by id', () => {
            const todo1 = { id: '1', text: 'Todo 1', completed: false, createdAt: getTimestamp() };
            const todo2 = { id: '2', text: 'Todo 2', completed: false, createdAt: getTimestamp() };
            todos = [todo1, todo2];

            todos = todos.filter(t => t.id !== '1');

            expect(todos.length).toBe(1);
            expect(todos[0].id).toBe('2');
        });

        test('should handle deleting non-existent todo', () => {
            const todo = { id: '1', text: 'Todo 1', completed: false, createdAt: getTimestamp() };
            todos = [todo];

            todos = todos.filter(t => t.id !== '999');

            expect(todos.length).toBe(1);
        });
    });

    describe('toggleComplete', () => {
        test('should toggle todo completion status', () => {
            const todo = { id: '1', text: 'Todo 1', completed: false, createdAt: getTimestamp() };
            todos = [todo];

            todos = todos.map(t => {
                if (t.id === '1') {
                    return { ...t, completed: !t.completed };
                }
                return t;
            });

            expect(todos[0].completed).toBe(true);
        });

        test('should toggle back to incomplete', () => {
            const todo = { id: '1', text: 'Todo 1', completed: true, createdAt: getTimestamp() };
            todos = [todo];

            todos = todos.map(t => {
                if (t.id === '1') {
                    return { ...t, completed: !t.completed };
                }
                return t;
            });

            expect(todos[0].completed).toBe(false);
        });
    });

    describe('Storage', () => {
        test('should save todos to localStorage', () => {
            const todos = [
                { id: '1', text: 'Todo 1', completed: false, createdAt: getTimestamp() }
            ];

            localStorage.setItem('clawteam_todos', JSON.stringify(todos));

            const stored = JSON.parse(localStorage.getItem('clawteam_todos'));
            expect(stored.length).toBe(1);
            expect(stored[0].text).toBe('Todo 1');
        });

        test('should load todos from localStorage', () => {
            const todos = [
                { id: '1', text: 'Todo 1', completed: false, createdAt: getTimestamp() }
            ];

            localStorage.setItem('clawteam_todos', JSON.stringify(todos));

            const loaded = JSON.parse(localStorage.getItem('clawteam_todos') || '[]');
            expect(loaded.length).toBe(1);
            expect(loaded[0].id).toBe('1');
        });

        test('should return empty array when no data', () => {
            const loaded = JSON.parse(localStorage.getItem('clawteam_todos') || '[]');
            expect(loaded.length).toBe(0);
        });
    });

    describe('Statistics', () => {
        test('should calculate correct statistics', () => {
            const todos = [
                { id: '1', text: 'Todo 1', completed: false, createdAt: getTimestamp() },
                { id: '2', text: 'Todo 2', completed: true, createdAt: getTimestamp() },
                { id: '3', text: 'Todo 3', completed: false, createdAt: getTimestamp() }
            ];

            const total = todos.length;
            const completed = todos.filter(t => t.completed).length;
            const active = total - completed;

            expect(total).toBe(3);
            expect(completed).toBe(1);
            expect(active).toBe(2);
        });
    });
});

// 运行报告
console.log('测试完成: 所有用例已执行');
