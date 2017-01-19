import 'myca_core.dart';
import 'myca_console.dart';

abstract class Item {
	String name(ItemStack stack);
	double size(ItemStack stack) => 0.0;
	bool stackable(ItemStack stack) => true;
	ConsoleColor color(ItemStack stack) => ConsoleColor.WHITE;
	
	bool canMerge(ItemStack stack, ItemStack other) {
		return (stack.stackable && other.stackable && stack.item == other.item);
	}
	ItemStack merge(ItemStack stack, ItemStack other) {
		stack.amt += other.amt;
		return stack;
	}
	
	ItemStack take(ItemStack stack, [int toTake = 1]) {
		stack.amt -= toTake;
		if (stack.amt <= 0) {
			return null;
		}
		return stack;
	}
	ItemStack give(ItemStack stack, [int toGive = 1]) {
		stack.amt += toGive;
		if (stack.amt <= 0) {
			return null;
		}
		return stack;
	}
	
}

class ItemStack {
	Item item;
	int amt;
	Object data;
	
	String _nameOverride;
	Inventory inventory;
	
	ItemStack(this.item, [this.amt = 1, this.data]);
	
	get name {
		String nameBase = _nameOverride ?? item.name(this);
		if (stackable && amt != 1) {
			nameBase += " (" + amt.toString() + ")";
		}
		return nameBase;
	}
	set name(String value) {
		_nameOverride = value;
	}
	
	get size => item.size(this);
	get stackable => item.stackable(this);
	get color => item.color(this);
	
	bool canMerge(ItemStack other) => item.canMerge(this, other);
	ItemStack merge(ItemStack other) => item.merge(this, other);
	
	ItemStack take([int toTake = 1]) => item.take(this, toTake);
	ItemStack give([int toGive = 1]) => item.give(this, toGive);
}

class Inventory {
	List<ItemStack> items = new List<ItemStack>();
	
	double maxSize;
	
	get size {
		double sum = 0.0;
		for (ItemStack i in items) {
			sum += i.size * i.amt;
		}
		return sum;
	}
	
	Inventory([this.maxSize]);
	
	void add(ItemStack stack) {
		int i = 0;
		bool merged = false;
		for (ItemStack other in items) {
			if (other.canMerge(stack)) {
				items[i] = other.merge(stack);
				items[i].inventory = this;
				merged = true;
				break;
			}
			i++;
		}
		
		if (!merged) {
			items.add(stack);
			stack.inventory = this;
		}
	}
	
	void addAll(Iterable<ItemStack> other) {
		for (ItemStack stack in other) {
			add(stack);
		}
	}
	
	void addInventory(Inventory other) {
		for (ItemStack stack in other.items) {
			add(stack);
		}
	}
}