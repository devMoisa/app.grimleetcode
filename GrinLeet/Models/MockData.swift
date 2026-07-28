import Foundation

enum MockData {
    static let problems: [Problem] = [
        Problem(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "Two Sum",
            difficulty: .easy,
            tags: ["Array", "Hash Table"],
            statement: """
            Given an array of integers `nums` and an integer `target`, return the indices of the two numbers such that they add up to `target`.

            You may assume that each input would have exactly one solution, and you may not use the same element twice.
            """,
            examples: [
                .init(
                    input: "nums = [2, 7, 11, 15], target = 9",
                    output: "[0, 1]",
                    explanation: "nums[0] + nums[1] == 9, so we return [0, 1]."
                ),
                .init(
                    input: "nums = [3, 2, 4], target = 6",
                    output: "[1, 2]",
                    explanation: nil
                ),
            ],
            constraints: [
                "2 <= nums.length <= 10^4",
                "-10^9 <= nums[i] <= 10^9",
                "Only one valid answer exists.",
            ],
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        ),
        Problem(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Longest Substring Without Repeating Characters",
            difficulty: .medium,
            tags: ["String", "Sliding Window", "Hash Table"],
            statement: """
            Given a string `s`, find the length of the longest substring without repeating characters.
            """,
            examples: [
                .init(input: "s = \"abcabcbb\"", output: "3", explanation: "The answer is \"abc\", with length 3."),
                .init(input: "s = \"bbbbb\"", output: "1", explanation: "The answer is \"b\"."),
            ],
            constraints: [
                "0 <= s.length <= 5 * 10^4",
                "s consists of English letters, digits, symbols and spaces.",
            ],
            createdAt: Date(timeIntervalSince1970: 1_700_000_100)
        ),
        Problem(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "Median of Two Sorted Arrays",
            difficulty: .hard,
            tags: ["Array", "Binary Search", "Divide and Conquer"],
            statement: """
            Given two sorted arrays `nums1` and `nums2` of size `m` and `n` respectively, return the median of the two sorted arrays.

            The overall run time complexity should be `O(log(m + n))`.
            """,
            examples: [
                .init(input: "nums1 = [1,3], nums2 = [2]", output: "2.00000", explanation: "Merged array = [1,2,3], median is 2."),
            ],
            constraints: [
                "nums1.length == m",
                "nums2.length == n",
                "0 <= m <= 1000",
            ],
            createdAt: Date(timeIntervalSince1970: 1_700_000_200)
        ),
        Problem(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "Valid Parentheses",
            difficulty: .easy,
            tags: ["Stack", "String"],
            statement: """
            Given a string `s` containing just the characters `'('`, `')'`, `'{'`, `'}'`, `'['` and `']'`, determine if the input string is valid.
            """,
            examples: [
                .init(input: "s = \"()\"", output: "true", explanation: nil),
                .init(input: "s = \"()[]{}\"", output: "true", explanation: nil),
                .init(input: "s = \"(]\"", output: "false", explanation: nil),
            ],
            constraints: [
                "1 <= s.length <= 10^4",
            ],
            createdAt: Date(timeIntervalSince1970: 1_700_000_300)
        ),
    ]
}
