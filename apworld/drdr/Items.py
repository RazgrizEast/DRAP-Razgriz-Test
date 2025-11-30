from enum import IntEnum
from typing import NamedTuple
from BaseClasses import Item
from Options import OptionError


class DRItemCategory(IntEnum):
    SKIP = 0,
    EVENT = 1,
    MISC = 2,
    TRAP = 3,


class DRItemData(NamedTuple):
    name: str
    dr_code: int
    category: DRItemCategory


class DRItem(Item):
    game: str = "Dead Rising Deluxe Remaster"

    @staticmethod
    def get_name_to_id() -> dict:
        base_id = 1230000
        return {item_data.name: (base_id + item_data.dr_code if item_data.dr_code is not None else None) for item_data in _all_items}


key_item_names = {
}


_all_items = [DRItemData(row[0], row[1], row[2]) for row in [    
    ("Victory", 1000, DRItemCategory.EVENT),
]]

item_descriptions = {}

item_dictionary = {item_data.name: item_data for item_data in _all_items}

def BuildItemPool(multiworld, count, options):
    item_pool = []
    included_itemcount = 0

    if options.guaranteed_items.value:
        for item_name in options.guaranteed_items.value:
            item = item_dictionary[item_name]
            item_pool.append(item)
            included_itemcount = included_itemcount + 1
    remaining_count = count - included_itemcount

    itemList = [item for item in _all_items]
    for i in range(remaining_count):
        item = multiworld.random.choice(itemList)
        item_pool.append(item)
    
    multiworld.random.shuffle(item_pool)
    return item_pool
