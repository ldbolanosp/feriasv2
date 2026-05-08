<?php

namespace App\Services\Legacy;

use RuntimeException;

class LegacySqlDumpParser
{
    /** @var array<string, string> */
    private array $fileContents = [];

    /** @var array<string, array<string, list<string>>> */
    private array $insertStatements = [];

    /**
     * @return list<array<string, int|string|null>>
     */
    public function parseTable(string $path, string $table): array
    {
        $records = [];

        foreach ($this->extractInsertStatements($path, $table) as $statement) {
            if (preg_match('/INSERT INTO `'.preg_quote($table, '/').'` \((.*?)\) VALUES\s*(.*)\s*;\s*$/s', $statement, $match) !== 1) {
                continue;
            }

            $columns = $this->parseColumns($match[1]);
            $rows = $this->parseRows($match[2]);

            foreach ($rows as $row) {
                $records[] = array_combine($columns, $row);
            }
        }

        return $records;
    }

    private function readFile(string $path): string
    {
        if (! array_key_exists($path, $this->fileContents)) {
            $contents = @file_get_contents($path);

            if ($contents === false) {
                throw new RuntimeException("No se pudo leer el archivo legacy: {$path}");
            }

            $this->fileContents[$path] = $contents;
        }

        return $this->fileContents[$path];
    }

    /**
     * @return list<string>
     */
    private function parseColumns(string $columns): array
    {
        return array_map(
            static fn (string $column): string => trim($column, " \t\n\r\0\x0B`"),
            explode(',', $columns)
        );
    }

    /**
     * @return list<list<int|string|null>>
     */
    private function parseRows(string $values): array
    {
        $rows = [];
        $row = [];
        $value = '';
        $insideString = false;
        $escapeNext = false;
        $insideRow = false;
        $length = strlen($values);

        for ($index = 0; $index < $length; $index++) {
            $character = $values[$index];

            if ($insideString) {
                if ($escapeNext) {
                    $value .= $character;
                    $escapeNext = false;

                    continue;
                }

                if ($character === '\\') {
                    $escapeNext = true;

                    continue;
                }

                if ($character === "'") {
                    $insideString = false;

                    continue;
                }

                $value .= $character;

                continue;
            }

            if (! $insideRow) {
                if ($character === '(') {
                    $insideRow = true;
                    $row = [];
                    $value = '';
                }

                continue;
            }

            if ($character === "'") {
                $insideString = true;

                continue;
            }

            if ($character === ',') {
                $row[] = $this->normalizeValue($value);
                $value = '';

                continue;
            }

            if ($character === ')') {
                $row[] = $this->normalizeValue($value);
                $rows[] = $row;
                $row = [];
                $value = '';
                $insideRow = false;

                continue;
            }

            $value .= $character;
        }

        return $rows;
    }

    private function normalizeValue(string $value): int|string|null
    {
        $trimmedValue = trim($value);

        if ($trimmedValue === '' || strtoupper($trimmedValue) === 'NULL') {
            return null;
        }

        if (preg_match('/^-?\d+$/', $trimmedValue) === 1) {
            return (int) $trimmedValue;
        }

        return $trimmedValue;
    }

    /**
     * @return list<string>
     */
    private function extractInsertStatements(string $path, string $table): array
    {
        if (isset($this->insertStatements[$path][$table])) {
            return $this->insertStatements[$path][$table];
        }

        $sql = $this->readFile($path);
        $needle = 'INSERT INTO `'.$table.'`';
        $offset = 0;
        $statements = [];

        while (($start = strpos($sql, $needle, $offset)) !== false) {
            $end = $this->findStatementEnd($sql, $start);

            if ($end === null) {
                break;
            }

            $statements[] = substr($sql, $start, $end - $start + 1);
            $offset = $end + 1;
        }

        $this->insertStatements[$path][$table] = $statements;

        return $statements;
    }

    private function findStatementEnd(string $sql, int $start): ?int
    {
        $insideString = false;
        $escapeNext = false;
        $length = strlen($sql);

        for ($index = $start; $index < $length; $index++) {
            $character = $sql[$index];

            if ($insideString) {
                if ($escapeNext) {
                    $escapeNext = false;

                    continue;
                }

                if ($character === '\\') {
                    $escapeNext = true;

                    continue;
                }

                if ($character === "'") {
                    $insideString = false;
                }

                continue;
            }

            if ($character === "'") {
                $insideString = true;

                continue;
            }

            if ($character === ';') {
                return $index;
            }
        }

        return null;
    }
}
