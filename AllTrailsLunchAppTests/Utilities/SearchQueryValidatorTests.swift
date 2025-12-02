//
//  SearchQueryValidatorTests.swift
//  AllTrailsLunchAppTests
//
//  Created by Tri Le on 02/12/25.
//

import XCTest
@testable import AllTrailsLunchApp

@MainActor
final class SearchQueryValidatorTests: XCTestCase {
    
    // MARK: - Valid Food/Restaurant Queries
    
    func testValidate_WithPizzaQuery_ReturnsValid() {
        // When
        let result = SearchQueryValidator.validate("pizza")
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidate_WithRestaurantQuery_ReturnsValid() {
        // When
        let result = SearchQueryValidator.validate("italian restaurant")
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidate_WithCuisineQuery_ReturnsValid() {
        // When
        let result = SearchQueryValidator.validate("thai food")
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidate_WithCoffeeQuery_ReturnsValid() {
        // When
        let result = SearchQueryValidator.validate("coffee shop")
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidate_WithEmptyQuery_ReturnsValid() {
        // When
        let result = SearchQueryValidator.validate("")
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidate_WithWhitespaceQuery_ReturnsValid() {
        // When
        let result = SearchQueryValidator.validate("   ")
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    // MARK: - Invalid Non-Food Queries
    
    func testValidate_WithCarQuery_ReturnsInvalid() {
        // When
        let result = SearchQueryValidator.validate("car dealership")
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains("food") ?? false || result.errorMessage?.contains("restaurant") ?? false)
    }
    
    func testValidate_WithSchoolQuery_ReturnsInvalid() {
        // When
        let result = SearchQueryValidator.validate("elementary school")
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidate_WithHotelQuery_ReturnsInvalid() {
        // When
        let result = SearchQueryValidator.validate("hotel near me")
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidate_WithGymQuery_ReturnsInvalid() {
        // When
        let result = SearchQueryValidator.validate("fitness gym")
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidate_WithBankQuery_ReturnsInvalid() {
        // When
        let result = SearchQueryValidator.validate("bank atm")
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
    
    // MARK: - Edge Cases
    
    func testValidate_WithRestaurantNameOnly_ReturnsValid() {
        // When - Specific restaurant names should be allowed (permissive approach)
        let result = SearchQueryValidator.validate("Joe's Diner")
        
        // Then
        XCTAssertTrue(result.isValid)
    }
    
    func testValidate_WithMixedCase_ReturnsInvalid() {
        // When
        let result = SearchQueryValidator.validate("CAR Dealership")
        
        // Then
        XCTAssertFalse(result.isValid)
    }
    
    func testValidate_WithPartialMatch_ReturnsInvalid() {
        // When
        let result = SearchQueryValidator.validate("looking for a car")
        
        // Then
        XCTAssertFalse(result.isValid)
    }
}

