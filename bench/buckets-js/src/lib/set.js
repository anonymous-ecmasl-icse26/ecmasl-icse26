// ------------------------------- dictionary.js -----------------------------

'use strict';

const buckets = require("../base")

const dictionary = require("./dictionary").Dictionary
buckets.Dictionary = dictionary

// ---------------------------------- set.js ---------------------------------

/**
 * Creates an empty set.
 * @class <p>A set is a data structure that contains no duplicate items.</p>
 * <p>If the inserted elements are custom objects, a function
 * that converts elements to unique strings must be provided at construction time.
 * <p>Example:</p>
 * <pre>
 * function petToString(pet) {
 *  return pet.type + ' ' + pet.name;
 * }
 * </pre>
 *
 * @param {function(Object):string=} toStringFunction Optional function used
 * to convert elements to unique strings. If the elements aren't strings or if toString()
 * is not appropriate, a custom function which receives an object and returns a
 * unique string must be provided.
 */
buckets.Set = function (toStringFunction) {

    /**
     * @exports theSet as buckets.Set
     * @private
     */
    var theSet = {},
        // Underlying storage.
        dictionary = new buckets.Dictionary(toStringFunction);

    /**
     * Returns true if the set contains the specified element.
     * @param {Object} element Element to search for.
     * @return {boolean} True if the set contains the specified element,
     * false otherwise.
     */
    /* @id set_contains */
    theSet.contains = function (element) {
        return dictionary.containsKey(element);
    };

    /**
     * Adds the specified element to the set if it's not already present.
     * @param {Object} element The element to insert.
     * @return {boolean} True if the set did not already contain the specified element.
     */
    /* @id set_add */
    theSet.add = function (element) {
        if (theSet.contains(element) || buckets.isUndefined(element)) {
            return false;
        }
        dictionary.set(element, element);
        return true;
    };

    /**
     * Performs an intersection between this and another set.
     * Removes all values that are not present in this set and the given set.
     * @param {buckets.Set} otherSet Other set.
     */
    /* @id set_intersection */
    theSet.intersection = function (otherSet) {
        /* @id set_intersection_callback */
        theSet.forEach(function (element) {
            if (!otherSet.contains(element)) {
                theSet.remove(element);
            }
        });
    };

    /**
     * Performs a union between this and another set.
     * Adds all values from the given set to this set.
     * @param {buckets.Set} otherSet Other set.
     */
    /* @id set_union */
    theSet.union = function (otherSet) {
        /* @id set_union_callback */
        otherSet.forEach(function (element) {
            theSet.add(element);
        });
    };

    /**
     * Performs a difference between this and another set.
     * Removes all the values that are present in the given set from this set.
     * @param {buckets.Set} otherSet other set.
     */
    /* @id set_difference */
    theSet.difference = function (otherSet) {
        /* @id set_difference_callback */
        otherSet.forEach(function (element) {
            theSet.remove(element);
        });
    };

    /**
     * Checks whether the given set contains all the elements of this set.
     * @param {buckets.Set} otherSet Other set.
     * @return {boolean} True if this set is a subset of the given set.
     */
    /* @id set_isSubsetOf */
    theSet.isSubsetOf = function (otherSet) {
        var isSub = true;

        if (theSet.size() > otherSet.size()) {
            return false;
        }
        /* @id set_isSubsetOf_callback */
        theSet.forEach(function (element) {
            if (!otherSet.contains(element)) {
                isSub = false;
                return false;
            }
        });
        return isSub;
    };

    /**
     * Removes the specified element from the set.
     * @return {boolean} True if the set contained the specified element, false
     * otherwise.
     */
    /* @id set_remove */
    theSet.remove = function (element) {
        if (!theSet.contains(element)) {
            return false;
        }
        dictionary.remove(element);
        return true;
    };

    /**
     * Executes the provided function once per element
     * present in the set.
     * @param {function(Object):*} callback Function to execute, it's
     * invoked an element as argument. To break the iteration you can
     * optionally return false inside the callback.
     */
    /* @id set_forEach */
    theSet.forEach = function (callback) {
        /* @id set_forEach_callback */
        dictionary.forEach(function (k, v) {
            return callback(v);
        });
    };

    /**
     * Returns an array containing all the elements in the set in no particular order.
     * @return {Array} An array containing all the elements in the set.
     */
    /* @id set_toArray */
    theSet.toArray = function () {
        return dictionary.values();
    };

    /**
     * Returns true if the set contains no elements.
     * @return {boolean} True if the set contains no elements.
     */
    /* @id set_isEmpty */
    theSet.isEmpty = function () {
        return dictionary.isEmpty();
    };

    /**
     * Returns the number of elements in the set.
     * @return {number} The number of elements in the set.
     */
    /* @id set_size */
    theSet.size = function () {
        return dictionary.size();
    };

    /**
     * Removes all the elements from the set.
     */
    /* @id set_clear */
    theSet.clear = function () {
        dictionary.clear();
    };

    /**
     * Returns true if the set is equal to another set.
     * Two sets are equal if they have the same elements.
     * @param {buckets.Set} other The other set.
     * @return {boolean} True if the set is equal to the given set.
     */
    /* @id set_equals */
    theSet.equals = function (other) {
        var isEqual;
        if (buckets.isUndefined(other) || typeof other.isSubsetOf !== 'function') {
            return false;
        }
        if (theSet.size() !== other.size()) {
            return false;
        }

        isEqual = true;
        /* @id set_equals_callback */
        other.forEach(function (element) {
            isEqual = theSet.contains(element);
            return isEqual;
        });
        return isEqual;
    };

    return theSet;
};

module.exports = buckets;
