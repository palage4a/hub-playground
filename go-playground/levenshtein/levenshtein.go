package levenshtein

import (
	_ "unicode/utf8"
)

// min возвращает минимальное из трех целых чисел
func min(a, b, c int) int {
	if a < b {
		if a < c {
			return a
		}
		return c
	}
	if b < c {
		return b
	}
	return c
}

// Distance вычисляет расстояние Левенштейна между двумя строками
func Distance(a, b string) int {
	// Преобразуем строки в руны для корректной работы с юникодом
	arunes := []rune(a)
	brunes := []rune(b)

	// Создаем матрицу для хранения промежуточных значений
	d := make([][]int, len(arunes)+1)
	for i := range d {
		d[i] = make([]int, len(brunes)+1)
	}

	// Инициализируем первую строку и первый столбец
	for i := 0; i <= len(arunes); i++ {
		d[i][0] = i
	}
	for j := 0; j <= len(brunes); j++ {
		d[0][j] = j
	}

	// Заполняем матрицу
	for i := 1; i <= len(arunes); i++ {
		for j := 1; j <= len(brunes); j++ {
			cost := 0
			if arunes[i-1] != brunes[j-1] {
				cost = 1
			}
			d[i][j] = min(
				d[i-1][j]+1,   // удаление
				d[i][j-1]+1,   // вставка
				d[i-1][j-1]+cost, // замена
			)
		}
	}

	// Возвращаем значение в правом нижнем углу матрицы
	return d[len(arunes)][len(brunes)]
}